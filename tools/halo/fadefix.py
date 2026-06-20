#!/usr/bin/env python3
import subprocess, os, glob, sys, shutil, array, math

APPLY="--apply" in sys.argv
SR=44100
FADE=0.010  # 10ms fast-attack fade-in to kill startup click/blip
REPO=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/sounds")
LIVE=os.path.expanduser("~/.claude/sounds")
BACKUP=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/.scratch/_fadefix_backup")

def envelope(path, frame=0.01):
    raw=subprocess.run(["ffmpeg","-hide_banner","-loglevel","error","-i",path,
        "-ac","1","-ar",str(SR),"-f","s16le","-"],capture_output=True).stdout
    a=array.array("h"); a.frombytes(raw[:len(raw)//2*2])
    fr=int(frame*SR); env=[]
    for i in range(0,len(a),fr):
        s=a[i:i+fr]
        if not s: break
        rms=math.sqrt(sum(x*x for x in s)/len(s))+1
        env.append(20*math.log10(rms/32768))
    return env, frame

def voice_onset(path):
    env,frame=envelope(path)
    if not env: return 0.0
    peak=max(env); thr=max(peak-32.0,-50.0)
    for i in range(len(env)):
        # sustained: >=6 of next 12 frames (120ms) above threshold => real voice, not a blip
        if env[i]>thr and sum(1 for d in env[i:i+12] if d>thr)>=6:
            return round(max(0.0, i*frame-0.005),3)
    return 0.0

# build work list: (src, [dest paths], backup_key)
jobs=[]
for pack in ("cortana","guilty-spark","sergeant-johnson"):
    repo_dir=f"{REPO}/{pack}"; live_dir=f"{LIVE}/{pack}"
    has_repo=os.path.isdir(repo_dir) and glob.glob(f"{repo_dir}/*/*.mp3")
    src_root = repo_dir if has_repo else live_dir
    for f in sorted(glob.glob(f"{src_root}/*/*.mp3")):
        rel=os.path.relpath(f, src_root)
        dests=[f"{live_dir}/{rel}"]
        if has_repo: dests=[f"{repo_dir}/{rel}", f"{live_dir}/{rel}"]
        jobs.append((f, dests, f"{pack}/{rel}"))

import collections
buckets=collections.Counter()
print(f"{'pack':16s} clips  trim:0   trim<0.3  trim>=0.3   (all get {int(FADE*1000)}ms fade-in)")
per=collections.defaultdict(lambda:[0,0,0,0])
plans=[]
for src,dests,key in jobs:
    t=voice_onset(src); plans.append((src,dests,key,t))
    pack=key.split('/')[0]; per[pack][0]+=1
    per[pack][1 if t<0.02 else (2 if t<0.3 else 3)]+=1
for pack,(n,a,b,c) in per.items():
    print(f"  {pack:14s} {n:4d}   {a:4d}     {b:4d}      {c:4d}")

if not APPLY:
    print("\nDRY RUN. add --apply."); sys.exit(0)

os.makedirs(BACKUP,exist_ok=True); done=0; fails=[]
TMPDIR=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/.scratch/_fftmp")
os.makedirs(TMPDIR,exist_ok=True)
for src,dests,key,t in plans:
    b=os.path.join(BACKUP,key); os.makedirs(os.path.dirname(b),exist_ok=True)
    if not os.path.exists(b): shutil.copy2(src,b)
    tmp=os.path.join(TMPDIR,"work.mp3")
    af=f"afade=t=in:st=0:d={FADE},aresample=44100"
    cmd=["ffmpeg","-hide_banner","-loglevel","error","-y"]
    if t>0.005: cmd+=["-ss",f"{t}"]
    cmd+=["-i",src,"-af",af,"-ac","1","-ar","44100","-c:a","libmp3lame","-b:a","128k",tmp]
    r=subprocess.run(cmd,capture_output=True,text=True)
    if r.returncode!=0 or not os.path.exists(tmp) or os.path.getsize(tmp)<500:
        fails.append((key, r.stderr.strip().split("\n")[-1] if r.stderr else "??"))
        if os.path.exists(tmp): os.remove(tmp)
        continue
    for d in dests:
        os.makedirs(os.path.dirname(d),exist_ok=True)
        shutil.copy2(tmp,d)
    os.remove(tmp); done+=1
print(f"\nProcessed {done} clips (trim + {int(FADE*1000)}ms fade-in). Backups: {BACKUP}")
if fails:
    print(f"FAILED {len(fails)}:")
    for k,e in fails: print(f"  {k}: {e}")
