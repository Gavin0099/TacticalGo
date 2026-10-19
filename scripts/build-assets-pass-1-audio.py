#!/usr/bin/env python3
"""Original deterministic standard-library synthesis, no samples/downloads/models.
Retains existing cue filenames in Audio/V30; never writes the Release originals.
ffmpeg is used only to measure EBU R128 / true peak before gain calibration.
"""
import array,hashlib,json,math,random,re,struct,subprocess,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ios/TacticalGo/Audio/V30';OUT.mkdir(parents=True,exist_ok=True);RATE=44100
BASE_SEED=301019
# (duration, design, loudness family). Each event is authored independently from primitives.
RECIPES={
 'selection':(.18,'select','ui'), 'place':(.48,'wood','contact'), 'capture':(.70,'fracture','contact'),
 'summon':(.98,'rise','cast'), 'warrior':(.85,'steel','cast'), 'mage':(.90,'crystal','cast'),
 'rogue':(.55,'slash','cast'), 'danger':(.65,'warning','alert'),
 'victory':(1.18,'major','ending'), 'defeat':(1.18,'minor','ending'), 'draw':(1.10,'neutral','ending'),
 'w7-brace':(.55,'brace','warrior'), 'w7-strike':(.80,'steel','warrior'), 'w7-land':(.50,'wood','warrior'),
 'p5-conjure':(.72,'gather','mage'), 'p5-push':(.68,'air','mage'), 'p5-contact':(.82,'crystal','mage'),
 'p8-rogue-coil':(.45,'cloth','rogue'), 'p8-rogue-dash':(.42,'slash','rogue'), 'p8-rogue-land':(.48,'leather','rogue'),
 'p8-priest-prayer':(.72,'page','priest'), 'p8-priest-bless':(.95,'bell','priest'), 'p8-priest-land':(.70,'soft','priest'),
 'confirm':(.32,'confirm','ui'), 'commander-capture':(1.08,'crown','ending')}
TARGET={'ui':-27,'contact':-21,'cast':-22,'alert':-23,'ending':-22,'warrior':-23,'mage':-23,'rogue':-23,'priest':-23}
def synth(duration,kind,seed):
 n=round(RATE*duration);a=[0.0]*n;rng=random.Random(seed)
 def tone(at,length,freq,amp,decay=5,bend=0,partials=(1,.25,.08),attack=.004):
  start=round(at*RATE);count=min(round(length*RATE),n-start)
  for i in range(max(0,count)):
   t=i/RATE;env=min(1,t/attack)*math.exp(-decay*t/max(.02,length));phase=2*math.pi*(freq*t+bend*t*t/2)
   a[start+i]+=amp*env*sum(g*math.sin((h+1)*phase) for h,g in enumerate(partials))
 def noise(at,length,amp,cut=1500,decay=5,rise=False):
  start=round(at*RATE);low=0.;prior=0.;alpha=1-math.exp(-2*math.pi*cut/RATE)
  for i in range(max(0,min(round(length*RATE),n-start))):
   t=i/RATE;v=rng.uniform(-1,1);low+=alpha*(v-low);hp=v-low
   env=min(1,t/.005)*math.exp(-decay*t/length)*(t/length if rise else 1)
   a[start+i]+=amp*(.85*low+(.20 if cut>2000 else .035)*hp)*env;prior=v
 if kind=='select':
  tone(0,.12,940,.26,6,partials=(1,.12));tone(.025,.10,1410,.08,5)
 elif kind=='confirm':
  tone(0,.16,660,.23,4,attack=.008);tone(.065,.20,990,.18,4,attack=.008)
 elif kind=='crown':
  tone(0,.80,65,.36,5,bend=-30);tone(.025,.60,131,.20,5)
  for i,f in enumerate([1900,2700,3500]):noise(i*.025,.10,.14,3800);tone(i*.035,.35,f,.07,7)
  tone(.30,.60,262,.16,4,attack=.02)
 elif kind in ['wood','leather','soft']:
  bass={'wood':125,'leather':180,'soft':245}[kind]
  tone(0,.60 if kind=='soft' else .40,bass,.42,3 if kind=='soft' else 7,bend=-10 if kind=='soft' else -45,partials=(1,.25,.08),attack=.035 if kind=='soft' else .004);tone(.003,.24,bass*2.71,.20,8,partials=(1,.12));noise(0,.09,.24,900 if kind!='soft' else 500)
  tone(.026,.18,480,.05,7);noise(.042,.12,.05,700)
 elif kind in ['fracture','steel','brace']:
  tone(0,.5,84 if kind=='steel' else 140,.4,7,bend=-50)
  for i,f in enumerate(([510,843,1437,2210] if kind=='steel' else [360,720,1185] if kind=='brace' else [1720,2410,3270,4360])):
   at=i*(.018 if kind=='fracture' else .005);tone(at,.35,f,.10,9,partials=(1,.09));noise(at,.045,.20 if kind=='fracture' else .09,3500)
  if kind=='fracture':
   for at in [.15,.21,.29]:noise(at,.05,.12,4800);tone(at,.13,2300-at*1400,.06,8)
 elif kind in ['slash','cloth','air','gather']:
  noise(0,duration*.72,.65,2700 if kind=='slash' else 1600,3,rise=True)
  tone(0,duration*.8,380 if kind=='slash' else 220,.08,4,bend=1300 if kind=='gather' else -220)
  if kind=='slash':noise(.07,.055,.28,6000);tone(.09,.12,1700,.08,8)
  if kind=='gather':tone(.10,.50,660,.10,4,bend=300)
 elif kind in ['crystal','bell','page','rise']:
  freqs={'crystal':[880,1320,2093],'bell':[523,784,1046],'page':[330,495],'rise':[262,392,523,784]}[kind]
  for i,f in enumerate(freqs):tone(i*.045,duration-i*.06,f,.20/(1+i*.25),4,partials=(1,.14,.04),attack=.012 if kind!='page' else .025)
  noise(0,.20,.08 if kind=='page' else .035,950)
 elif kind=='warning':
  for at in [0,.24]:tone(at,.22,330,.24,5,partials=(1,.3));tone(at,.22,348,.14,6)
 elif kind in ['major','minor','neutral']:
  notes={'major':[392,494,587,784],'minor':[392,349,311,196],'neutral':[392,440,392]}[kind]
  for i,f in enumerate(notes):tone(i*.16,.60,f,.25,5,partials=(1,.25,.10),attack=.012)
 # Dry direct attack plus authored short early reflections; unlike a long generic reverb wash.
 direct=a[:]
 for delay,gain in [(.019,.13),(.043,.075),(.079,.035)]:
  offset=round(delay*RATE)
  for i in range(offset,n):a[i]+=direct[i-offset]*gain
 # Exact zero endpoints and 25ms fade guarantee click-free short tails.
 for i in range(n):a[i]*=min(1,i/(RATE*.003),(n-1-i)/(RATE*.025))
 # Static soft saturation before calibration creates rounded attacks, not clipped PCM.
 return [math.tanh(v*1.1) for v in a]
def write(path,a):
 data=array.array('h')
 for v in a:
  s=round(max(-.999,min(.999,v))*32767);data.extend([s,s])
 with wave.open(str(path),'wb') as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(data.tobytes())
def measure(path,duration):
 af=('apad=whole_dur=0.4,' if duration<.4 else '')+'ebur128=peak=true'
 proc=subprocess.run(['ffmpeg','-hide_banner','-nostats','-i',str(path),'-af',af,'-f','null','-'],capture_output=True,text=True,check=True)
 return float(re.findall(r'I:\s*(-?[\d.]+) LUFS',proc.stderr)[-1]),float(re.findall(r'Peak:\s*(-?[\d.]+) dBFS',proc.stderr)[-1])
assets=[];seeds={}
for idx,(key,(duration,kind,family)) in enumerate(RECIPES.items()):
 seed=BASE_SEED+idx;seeds[key]=seed;a=synth(duration,kind,seed);p=OUT/(key+'.wav');write(p,a);lu,tp=measure(p,duration)
 gain=10**((TARGET[family]-lu)/20);gain=min(gain,10**(-1.5/20)/(max(abs(x) for x in a)+1e-20));a=[v*gain for v in a];write(p,a);lu,tp=measure(p,duration)
 assert tp<=-1.0,(key,tp)
 assets.append(dict(key=key,file=p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),frames=len(a),duration_seconds=duration,sample_rate_hz=RATE,channels=2,bits_per_sample=16,peak_dbfs=round(20*math.log10(max(abs(v) for v in a)),2),rms_dbfs=round(20*math.log10(math.sqrt(sum(v*v for v in a)/len(a))),2),boundary_jump_pcm=0,integrated_lufs=lu,true_peak_dbfs=tp,family=family,design=kind,loop=False))
 print(key,lu,tp,flush=True)
for family in TARGET:
 vals=[a['integrated_lufs'] for a in assets if a['family']==family];assert max(vals)-min(vals)<=2,(family,vals)
manifest=dict(schema_version=1,candidate='ASSETS-PASS-1 V30 original procedural candidate',created_for='TacticalGo',composition_date='2026-10-19',source='scripts/build-assets-pass-1-audio.py',source_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),generation='Python3 standard library additive/subtractive synthesis, fixed seed noise, original modal/chord events, authored early reflections. ffmpeg EBU R128 gain measurement only; no samples/downloads/models',seed=seeds,rights={'third_party_inputs':[],'external_sample_license':'not applicable; no external recordings','publication_status':'Beta/DEBUG candidate only; owner listening and rights acceptance pending'},music={'changed':False,'reason':'existing B music and end phrases retained; measured separately'},loudness={'method':'ffmpeg -af ebur128=peak=true; sub400ms padded to400ms','family_targets_lufs':TARGET,'true_peak_limit_dbfs':-1,'duration_limit_seconds':1.2},assets=assets)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
