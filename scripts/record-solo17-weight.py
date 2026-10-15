#!/usr/bin/env python3
"""Normal-speed actual native recordings; silent Simulator capture, no physical AV claim."""
import json,signal,subprocess,time
from pathlib import Path
R=Path(__file__).resolve().parents[1];O=R/'artifacts/v11/solo-17/video';O.mkdir(exist_ok=True)
D='401DDDA0-8AA8-4A55-A61E-8FC9A7BB7C28';APP='com.tacticalgo.prototype'
records=[]
for name,args in [('before', ['--warrior-weight-before']),('weighted',[])]:
 raw=O/(name+'-native-silent.mp4');clock=O/(name+'-receipt.log')
 if raw.exists(): raise SystemExit('Existing raw must be retained; review before repeating capture')
 rec=subprocess.Popen(['xcrun','simctl','io',D,'recordVideo','--codec=h264',str(raw)],stderr=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
 lines=[]
 while True:
  line=rec.stderr.readline();assert line,'Recorder not ready';lines.append(line)
  if 'Recording started' in line:break
 ready=time.time()
 try:
  subprocess.run(['xcrun','simctl','launch','--terminate-running-process','--stdout='+str(clock),D,APP,'--solo-warrior-review','--integrated-review-audit','--exp-autoplay']+args,check=True,stdout=subprocess.DEVNULL)
  time.sleep(12)
 finally:
  rec.send_signal(signal.SIGINT);_,tail=rec.communicate(timeout=20);(O/(name+'-recorder.log')).write_text(''.join(lines)+tail)
 assert 'EXPANSION_RECEIPT' in clock.read_text()
 records.append({'name':name,'raw':str(raw.relative_to(R)),'receipt':str(clock.relative_to(R)),'readyWall':ready,'platform':'actual SwiftUI iOS Simulator,375pt/9x9','audio':'silent native screen capture; unchanged EnglishB/SFX exercised by native receipt test, no AV quality claim','speed':'normal 1x','fixture':'engineering commander capture, not legal-opening reachability claim'})
(O/'MANIFEST.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n')
