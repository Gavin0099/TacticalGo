"""Trim native recording around successful receipt clocks; keep normal playback speed and no audio."""
import json
import pathlib
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[1]
MEDIA = ROOT/"artifacts/ios/anim-mage-body-01/media"
clock = json.loads((MEDIA/"capture-clock.json").read_text())
receipts = [r for r in json.loads((MEDIA/"game-feel-receipts.json").read_text()) if r["receiptUptime"] >= clock["recordReadyUptime"]]
assert len(receipts) == 6, "Expected 2 tempos × (summon, push, capture); do not invent missing action footage"
clips = []
audit = []
for i,r in enumerate(receipts):
    kind = "SUMMON" if r["action"].startswith("summonHero") else "PUSH + REAL CAPTURE" if any("piecesCaptured" in e for e in r["events"]) else "PUSH"
    start = max(0,r["receiptUptime"]-clock["recordReadyUptime"]-0.45)
    duration = r["visualDuration"]+1.05
    caption = MEDIA/f"caption-{i}.txt"
    caption.write_text(f"{r['mageTempo'].upper()} / {kind}\nNative Simulator / silent / no particles or rings")
    caption_image = MEDIA/f"caption-{i}.png"
    label = Image.new("RGB",(540,64),"#243F43")
    draw = ImageDraw.Draw(label)
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf",16)
    draw.multiline_text((16,8),caption.read_text(),font=font,fill="white",spacing=6)
    label.save(caption_image)
    destination = MEDIA/f"native-{i}-{r['mageTempo']}.mp4"
    vf = "[0:v]fps=30,scale=540:-2,pad=iw:ih+64:0:0:color=0x243F43[screen];[screen][1:v]overlay=0:main_h-64[v]"
    subprocess.run(["ffmpeg","-y","-v","error","-ss",str(start),"-i",str(MEDIA/"native-ui-silent.mov"),"-i",str(caption_image),"-t",str(duration),"-filter_complex",vf,"-map","[v]","-an","-c:v","libx264","-crf","19","-pix_fmt","yuv420p","-movflags","+faststart",str(destination)],check=True)
    clips.append(destination)
    audit.append({"receipt":r["id"],"tempo":r["mageTempo"],"action":r["action"],"before":r["before"],"after":r["after"],"events":r["events"],"trim_start":start,"trim_duration":duration,"speed":1.0,"audio":"none","file":str(destination.relative_to(ROOT))})
for name,chosen in [("mage-body-board-demo.mp4",clips),("mage-body-full.mp4",clips[:3]),("mage-body-compact.mp4",clips[3:])]:
    listing = MEDIA/(name+".concat")
    listing.write_text("".join("file '"+str(f)+"'\n" for f in chosen))
    subprocess.run(["ffmpeg","-y","-v","error","-f","concat","-safe","0","-i",str(listing),"-an","-c","copy","-movflags","+faststart",str(MEDIA/name)],check=True)
# The final two native gesture samples are on a labelled pose-inspection screen.
# They are separately labelled and never substituted for real game action footage.
last_action = receipts[-1]["receiptUptime"]-clock["recordReadyUptime"]
close_start = max(last_action+3,clock["recordStopUptime"]-clock["recordReadyUptime"]-5.4)
subprocess.run(["ffmpeg","-y","-v","error","-ss",str(close_start),"-i",str(MEDIA/"native-ui-silent.mov"),"-t","4.8","-vf","fps=30,scale=540:-2","-an","-c:v","libx264","-crf","19","-pix_fmt","yuv420p","-movflags","+faststart",str(MEDIA/"mage-body-closeup.mp4")],check=True)
(MEDIA/"edit-audit.json").write_text(json.dumps({"source":"actual native-ui-silent.mov","claim":"native Simulator, not physical iPhone; no retiming, synthetic frames or postmixed audio","clockBoundary":"receipt/recorder-readiness offset, not a hardware timing measurement","clips":audit,"closeup":{"trim_start":close_start,"kind":"pose art inspection, not Domain settlement"}},indent=2)+"\n")
print("Native six-receipt normal-speed silent montage written")
