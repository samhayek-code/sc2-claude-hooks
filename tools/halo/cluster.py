#!/usr/bin/env python3
import subprocess, os, glob, sys
import numpy as np

SR=16000
B=os.path.expanduser("~/Desktop/Code/claude-audio-hooks/.scratch/_fadefix_backup")
WIN=int(0.35*SR)      # compare first 350ms from onset
LAG=int(0.006*SR)     # +-6ms alignment search

def load(path):
    raw=subprocess.run(["ffmpeg","-hide_banner","-loglevel","error","-i",path,
        "-ac","1","-ar",str(SR),"-f","s16le","-"],capture_output=True).stdout
    return np.frombuffer(raw[:len(raw)//2*2], dtype=np.int16).astype(np.float32)

def env_db(x, frame):
    n=len(x)//frame
    if n==0: return np.array([-120.0])
    f=x[:n*frame].reshape(n,frame)
    rms=np.sqrt((f*f).mean(axis=1))+1
    return 20*np.log10(rms/32768.0)

def structure(x):
    """Return (onset_s, region1_end_s, voice_onset_s) in seconds."""
    fr=int(0.01*SR)
    e=env_db(x,fr); peak=e.max(); thr=max(peak-35.0,-55.0)
    above=e>thr
    if not above.any(): return 0.0,0.0,0.0
    onset=int(np.argmax(above))
    # find first gap (>=40ms below thr) after onset
    i=onset; r1end=None
    while i<len(e):
        if not above[i]:
            j=i
            while j<len(e) and not above[j]: j+=1
            if (j-i)>=4:   # 40ms gap
                r1end=i; voice=j if j<len(e) else i
                return onset*0.01, r1end*0.01, voice*0.01
            i=j
        else: i+=1
    return onset*0.01, len(e)*0.01, onset*0.01  # no gap

def head(x, onset_s):
    s=int(onset_s*SR)
    seg=x[s:s+WIN]
    if len(seg)<WIN: seg=np.pad(seg,(0,WIN-len(seg)))
    seg=seg-seg.mean()
    n=np.linalg.norm(seg)
    return seg/n if n>0 else seg

def corr(a,b):
    best=-1
    for lag in range(-LAG,LAG+1,2):
        if lag>=0: c=np.dot(a[lag:],b[:len(b)-lag])
        else: c=np.dot(a[:len(a)+lag],b[-lag:])
        if c>best: best=c
    return best

files=sorted(glob.glob(f"{B}/*/*/*.mp3"))
data=[]
for f in files:
    x=load(f); on,r1,vo=structure(x)
    data.append({"f":f,"x":x,"on":on,"r1":r1,"vo":vo,"head":head(x,on),
                 "gap":vo-r1,"reglen":r1-on})

# greedy clustering by correlation
clusters=[]
for d in data:
    placed=False
    for cl in clusters:
        if corr(d["head"], cl["rep"])>0.62:
            cl["members"].append(d); placed=True; break
    if not placed:
        clusters.append({"rep":d["head"],"members":[d]})
clusters.sort(key=lambda c:-len(c["members"]))

print(f"{len(files)} clips -> {len(clusters)} clusters\n")
for i,cl in enumerate(clusters):
    m=cl["members"]
    reglens=np.array([d["reglen"] for d in m])
    gaps=np.array([d["gap"] for d in m])
    vos=np.array([d["vo"] for d in m])
    kind="PING variant" if len(m)>=3 else "unique/voice-first"
    print(f"cluster {i}: {len(m):3d} clips  reg1≈{np.median(reglens):.2f}s gap≈{np.median(gaps):.2f}s voiceOnset≈{np.median(vos):.2f}s  [{kind}]")
    for d in m[:3]:
        print(f"      {os.path.relpath(d['f'],B)}")
