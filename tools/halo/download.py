#!/usr/bin/env python3
import json, os, re, subprocess, sys

SCRATCH = os.path.dirname(os.path.abspath(__file__))
REPO_SOUNDS = os.path.abspath(os.path.join(SCRATCH, "..", "sounds"))

# Load catalogs
cat = {}
for fn in ("cortana_h3", "cortana_h2", "spark_h3"):
    cat[fn] = {s["t"]: s for s in json.load(open(os.path.join(SCRATCH, f"{fn}.json")))}

def slug(t):
    s = re.sub(r"[^a-z0-9]+", "-", t.lower()).strip("-")
    return s[:48] or "clip"

# (pack, bucket, source, transcript)
PICKS = [
    # ---------- CORTANA (Halo 2 board 47278 only; 10/bucket) ----------
    # NOTE: authoritative rebuilder is build_cortana_h2.py (it also trims + mirrors
    # to live). Kept here in sync so a full download.py run won't repollute.
    ("cortana","session-start","cortana_h2","You look nice."),
    ("cortana","session-start","cortana_h2","Don't make a girl a promise."),
    ("cortana","session-start","cortana_h2","You always bring me to such nice places."),
    ("cortana","session-start","cortana_h2","Right this way."),
    ("cortana","session-start","cortana_h2","Come on, chief."),
    ("cortana","session-start","cortana_h2","Go on through."),
    ("cortana","session-start","cortana_h2","This way, chief."),
    ("cortana","session-start","cortana_h2","Over here, chief."),
    ("cortana","session-start","cortana_h2","Here comes our ride."),
    ("cortana","session-start","cortana_h2","Let me get those doors."),

    ("cortana","task-complete","cortana_h2","Gladly."),
    ("cortana","task-complete","cortana_h2","Understood, ma'am."),
    ("cortana","task-complete","cortana_h2","Yes, ma'am."),
    ("cortana","task-complete","cortana_h2","I guess so."),
    ("cortana","task-complete","cortana_h2","Pretty much."),
    ("cortana","task-complete","cortana_h2","We're fine."),
    ("cortana","task-complete","cortana_h2","I like crazy."),
    ("cortana","task-complete","cortana_h2","That's all of the Marines, chief. Good work."),
    ("cortana","task-complete","cortana_h2","Don't worry, you can pick me up later."),
    ("cortana","task-complete","cortana_h2","Unfortunately for us both."),

    ("cortana","needs-permission","cortana_h2","Just one question."),
    ("cortana","needs-permission","cortana_h2","You all right, Chief?"),
    ("cortana","needs-permission","cortana_h2","What if you miss?"),
    ("cortana","needs-permission","cortana_h2","Who's in charge now, corporal?"),
    ("cortana","needs-permission","cortana_h2","Talk to me. Should I start CPR? What's going on?"),
    ("cortana","needs-permission","cortana_h2","Could we possibly make any more noise?"),
    ("cortana","needs-permission","cortana_h2","You think they'd notice you're in a tank?"),
    ("cortana","needs-permission","cortana_h2","Blink if you can hear me, chief."),
    ("cortana","needs-permission","cortana_h2","What? Is that?"),
    ("cortana","needs-permission","cortana_h2","Malta, what is your status over?"),

    ("cortana","error","cortana_h2","Shoot."),
    ("cortana","error","cortana_h2","Uh oh."),
    ("cortana","error","cortana_h2","You don't want to know."),
    ("cortana","error","cortana_h2","Wait, go back."),
    ("cortana","error","cortana_h2","It's berserking."),
    ("cortana","error","cortana_h2","Watch out Chief Wraiths on the far side."),
    ("cortana","error","cortana_h2","We're out of time, chief, into the conduit."),
    ("cortana","error","cortana_h2","Transcendence, huh? More like mass suicide."),
    ("cortana","error","cortana_h2","And people say I've got a big head."),
    ("cortana","error","cortana_h2","Easier said than done, inbound Phantoms chief."),

    # ---------- GUILTY SPARK ----------
    ("guilty-spark","session-start","spark_h3","Come inside, reclaimer."),
    ("guilty-spark","session-start","spark_h3","Of course Reclaimer."),
    ("guilty-spark","session-start","spark_h3","Here we are. Please follow me."),
    ("guilty-spark","session-start","spark_h3","Reclaimer."),
    ("guilty-spark","session-start","spark_h3","I will gladly aid the reclaimer's progress."),

    ("guilty-spark","task-complete","spark_h3","Success."),
    ("guilty-spark","task-complete","spark_h3","The bridge is stable."),
    ("guilty-spark","task-complete","spark_h3","Yes, isn't it?"),
    ("guilty-spark","task-complete","spark_h3","I will certainly try my best."),

    ("guilty-spark","needs-permission","spark_h3","What will you do?"),
    ("guilty-spark","needs-permission","spark_h3","Then decide which protocols apply."),
    ("guilty-spark","needs-permission","spark_h3","I beg your pardon?"),
    ("guilty-spark","needs-permission","spark_h3","For what purpose?"),
    ("guilty-spark","needs-permission","spark_h3","Come it awaits your approval."),

    ("guilty-spark","error","spark_h3","This just won't do."),
    ("guilty-spark","error","spark_h3","Protocol dictates action."),
    ("guilty-spark","error","spark_h3","I see now that helping you was wrong."),
    ("guilty-spark","error","spark_h3","You leave me no choice, Reclaimer."),
    ("guilty-spark","error","spark_h3","Indignant."),
]

ok, miss, fail = 0, [], []
for pack, bucket, src, t in PICKS:
    snd = cat[src].get(t)
    if not snd:
        miss.append((src, t)); continue
    dest_dir = os.path.join(REPO_SOUNDS, pack, bucket)
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, slug(t) + ".mp3")
    url = snd["url"]
    if not url.startswith("http"):
        url = "https://www.101soundboards.com" + url
    r = subprocess.run(["curl","-sfL","-A","Mozilla/5.0",url,"-o",dest],
                       capture_output=True)
    if r.returncode == 0 and os.path.getsize(dest) > 1000:
        ok += 1
    else:
        fail.append((t, r.returncode));
        if os.path.exists(dest): os.remove(dest)

print(f"downloaded={ok}  missing_transcript={len(miss)}  download_failed={len(fail)}")
for s,t in miss: print(f"  MISS [{s}] {t!r}")
for t,rc in fail: print(f"  FAIL ({rc}) {t!r}")
