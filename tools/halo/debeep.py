#!/usr/bin/env python3
import subprocess, os, glob, sys, shutil
import numpy as np

APPLY="--apply" in sys.argv
SR=16000
SRC=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/.scratch/_fadefix_backup")  # originals
REPO=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/sounds")
LIVE=os.path.expanduser("~/.claude/sounds")
TMP=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/.scratch/_dbtmp"); os.makedirs(TMP,exist_ok=True)

def load(p):
    raw=subprocess.run(["ffmpeg","-hide_banner","-loglevel","error","-i",p,"-ac","1","-ar",str(SR),"-f","s16le","-"],capture_output=True).stdout
    return np.frombuffer(raw[:len(raw)//2*2],dtype=np.int16).astype(np.float32)

def regions(x, fr=0.02, thr_off=35, mingap=0.04):
    f=int(fr*SR); n=len(x)//f
    if n==0: return []
    e=20*np.log10(np.sqrt((x[:n*f].reshape(n,f)**2).mean(1))+1)-20*np.log10(32768)
    thr=max(e.max()-thr_off,-55); above=e>thr
    segs=[]; i=0
    while i<n:
        if above[i]:
            j=i
            while j<n and above[j]: j+=1
            segs.append([i*fr,j*fr]); i=j
        else: i+=1
    # merge regions separated by < mingap (keep true gaps only)
    merged=[]
    for s in segs:
        if merged and s[0]-merged[-1][1] < mingap: merged[-1][1]=s[1]
        else: merged.append(s)
    return merged

def trim_point(x):
    segs=regions(x)
    if len(segs)>=2:
        reglen=segs[0][1]-segs[0][0]
        # region1 is a ping only if it's SHORT and near the start.
        # long region1 = it's the voice itself -> never trim (would destroy speech).
        if segs[0][0] < 1.0 and reglen <= 0.60:
            return round(max(0.0, segs[1][0]-0.03),3), len(segs)
    return 0.0, len(segs)

files=sorted(glob.glob(f"{SRC}/*/*/*.mp3"))
rows=[]
for f in files:
    t,nseg=trim_point(load(f))
    rows.append((f,t,nseg))

trimmed=[r for r in rows if r[1]>0.02]
left=[r for r in rows if r[1]<=0.02]
big=[r for r in rows if r[1]>1.7]
print(f"{len(files)} clips: {len(trimmed)} will trim, {len(left)} left as-is")
print(f"\nLEFT AS-IS (single region / no clear ping+gap) — {len(left)}:")
for f,t,n in left: print(f"   {os.path.relpath(f,SRC)[:-4]}  (regions={n})")
print(f"\nLARGE trims >1.7s (double-check these) — {len(big)}:")
for f,t,n in big: print(f"   {t:.2f}s  {os.path.relpath(f,SRC)[:-4]}")

if not APPLY:
    print("\nDRY RUN. add --apply."); sys.exit(0)

done=0
for f,t,nseg in rows:
    rel=os.path.relpath(f,SRC); pack=rel.split('/')[0]
    dests=[f"{LIVE}/{rel}"]
    if glob.glob(f"{REPO}/{pack}/*/*.mp3"): dests.insert(0,f"{REPO}/{rel}")
    tmp=os.path.join(TMP,"w.mp3")
    cmd=["ffmpeg","-hide_banner","-loglevel","error","-y"]
    if t>0.02: cmd+=["-ss",f"{t}"]
    cmd+=["-i",f,"-af","afade=t=in:st=0:d=0.008,aresample=44100","-ac","1","-ar","44100","-c:a","libmp3lame","-b:a","128k",tmp]
    r=subprocess.run(cmd,capture_output=True)
    if r.returncode!=0 or not os.path.exists(tmp): print("FAIL",rel); continue
    for d in dests:
        os.makedirs(os.path.dirname(d),exist_ok=True); shutil.copy2(tmp,d)
    done+=1
print(f"\nApplied to {done} clips (trim-to-voice + 8ms fade). Source originals safe in {SRC}")
