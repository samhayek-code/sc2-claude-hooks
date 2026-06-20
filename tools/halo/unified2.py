#!/usr/bin/env python3
import subprocess, os, glob, sys, shutil
import numpy as np

APPLY="--apply" in sys.argv
SR=16000
SRC=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/.scratch/_fadefix_backup")
REPO=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/sounds")
LIVE=os.path.expanduser("~/.claude/sounds")
TMP=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/.scratch/_u2tmp"); os.makedirs(TMP,exist_ok=True)
WIN=int(0.5*SR); LAG=int(0.006*SR)
PLUG_REF=f"{SRC}/cortana/task-complete/pretty-much.mp3"   # known 101 plug at start

def load(p):
    raw=subprocess.run(["ffmpeg","-hide_banner","-loglevel","error","-i",p,"-ac","1","-ar",str(SR),"-f","s16le","-"],capture_output=True).stdout
    return np.frombuffer(raw[:len(raw)//2*2],dtype=np.int16).astype(np.float32)
def regions(x, fr=0.02, thr_off=35, mingap=0.05):
    f=int(fr*SR); n=len(x)//f
    if n==0: return []
    e=20*np.log10(np.sqrt((x[:n*f].reshape(n,f)**2).mean(1))+1)-20*np.log10(32768)
    thr=max(e.max()-thr_off,-55); above=e>thr; segs=[]; i=0
    while i<n:
        if above[i]:
            j=i
            while j<n and above[j]: j+=1
            segs.append([i*fr,j*fr]); i=j
        else: i+=1
    m=[]
    for s in segs:
        if m and s[0]-m[-1][1]<mingap: m[-1][1]=s[1]
        else: m.append(s)
    return m
def feat_at(x, t):
    s=int(t*SR); seg=x[s:s+WIN]
    if len(seg)<WIN: seg=np.pad(seg,(0,WIN-len(seg)))
    seg=seg-seg.mean(); nrm=np.linalg.norm(seg)
    return seg/nrm if nrm>0 else seg
def corr(a,b):
    best=-1.0
    for lag in range(-LAG,LAG+1,2):
        c=np.dot(a[lag:],b[:len(b)-lag]) if lag>=0 else np.dot(a[:len(a)+lag],b[-lag:])
        if c>best: best=c
    return best

files=sorted(glob.glob(f"{SRC}/*/*/*.mp3"))
D=[]
for f in files:
    x=load(f); segs=regions(x)
    D.append({"f":f,"x":x,"segs":segs,
              "feat":feat_at(x,segs[0][0]) if segs else feat_at(x,0)})
# cluster openings -> intro centroids
clusters=[]
for d in D:
    for cl in clusters:
        if corr(d["feat"],cl[0]["feat"])>0.72: cl.append(d); break
    else: clusters.append([d])
# Use REAL instances as references (averaging blurs identical pings). Up to 2 reps/cluster.
centroids=[]
for cl in clusters:
    if len(cl)>=3:
        centroids.append(cl[0]["feat"])
        if len(cl)>=8: centroids.append(cl[len(cl)//2]["feat"])
# explicit plug reference (opening of a known plugged clip)
px=load(PLUG_REF); pseg=regions(px)
centroids.append(feat_at(px, pseg[0][0] if pseg else 0))
print(f"{len(centroids)} intro references (ping-variant instances + plug)")

def voice_onset(d):
    segs=d["segs"]; idx=0; stripped=0
    while idx<len(segs) and stripped<3:
        fc=feat_at(d["x"],segs[idx][0])
        if max(corr(fc,c) for c in centroids)>0.72:
            idx+=1; stripped+=1
        else: break
    if stripped==0 or idx>=len(segs): return 0.0, stripped
    return round(max(0.0,segs[idx][0]-0.03),3), stripped

for d in D: d["trim"],d["strip"]=voice_onset(d)
trimmed=[d for d in D if d["trim"]>0.02]
left=[d for d in D if d["trim"]<=0.02]
print(f"{len(files)} clips: {len(trimmed)} stripped, {len(left)} left")
print(f"\nLEFT ({len(left)}):")
for d in left: print(f"   {os.path.relpath(d['f'],SRC)[:-4]}  (regions={len(d['segs'])})")
print(f"\nMULTI-STRIP (ping+plug etc, stripped>=2):")
for d in trimmed:
    if d["strip"]>=2: print(f"   {d['trim']:.2f}s x{d['strip']}  {os.path.relpath(d['f'],SRC)[:-4]}")

if not APPLY:
    print("\nDRY RUN. add --apply."); sys.exit(0)
done=0
for d in D:
    f=d["f"]; rel=os.path.relpath(f,SRC); pack=rel.split('/')[0]
    dests=[f"{LIVE}/{rel}"]
    if glob.glob(f"{REPO}/{pack}/*/*.mp3"): dests.insert(0,f"{REPO}/{rel}")
    tmp=os.path.join(TMP,"w.mp3"); cmd=["ffmpeg","-hide_banner","-loglevel","error","-y"]
    if d["trim"]>0.02: cmd+=["-ss",f"{d['trim']}"]
    cmd+=["-i",f,"-af","afade=t=in:st=0:d=0.008,aresample=44100","-ac","1","-ar","44100","-c:a","libmp3lame","-b:a","128k",tmp]
    if subprocess.run(cmd,capture_output=True).returncode!=0 or not os.path.exists(tmp): print("FAIL",rel); continue
    for dd in dests:
        os.makedirs(os.path.dirname(dd),exist_ok=True); shutil.copy2(tmp,dd)
    done+=1
print(f"\nApplied to {done} clips. Originals safe in {SRC}")
