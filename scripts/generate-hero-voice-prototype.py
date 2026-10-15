#!/usr/bin/env python3
"""Offline Piper prototype. Requires piper-tts 1.8.0; model is not bundled in app.
Download en_US-libritts-high.onnx and matching .json from the pinned source.
Run this script with --model /path/to/en_US-libritts-high.onnx.
"""
import argparse,pathlib,json,hashlib,wave,array,math,tempfile,importlib.metadata
from piper import PiperVoice, SynthesisConfig
import onnxruntime
ROOT=pathlib.Path(__file__).resolve().parents[1];OUT=ROOT/'ios/TacticalGo/Audio/Voice'
MODEL_SHA='9127a559e11603f10b366d1a20ac7426826081dbc521de4c2420c57728d73f0f'
# Anonymous model speaker indices: one consistent voice/speed per hero pair.
# Casting is a placeholder; no named actor or existing game character is imitated.
LINES=[('warrior','summon','You can count on me!',0,.78),('warrior','skill','Hold the line!',0,.78),('mage','summon','Let the magic begin!',1,.80),('mage','skill','Off you go!',1,.80),('rogue','summon',"Guess who's here?",2,.74),('rogue','skill',"Let's switch!",2,.74)]
arg=argparse.ArgumentParser();arg.add_argument('--model',type=pathlib.Path,required=True);args=arg.parse_args()
assert hashlib.sha256(args.model.read_bytes()).hexdigest()==MODEL_SHA,'Unexpected model; review source first'
onnxruntime.set_seed(1710);voice=PiperVoice.load(str(args.model));OUT.mkdir(parents=True,exist_ok=True);rows=[]
for hero,trigger,text,speaker,speed in LINES:
 key='voice-'+hero+'-'+trigger;path=OUT/(key+'.wav');onnxruntime.set_seed(1710)
 with tempfile.TemporaryDirectory(prefix='tacticalgo-vo-') as tmp:
  raw=pathlib.Path(tmp)/'raw.wav'
  with wave.open(str(raw),'wb') as f: voice.synthesize_wav(text,f,syn_config=SynthesisConfig(speaker_id=speaker,length_scale=speed,noise_scale=.55,noise_w_scale=.65))
  with wave.open(str(raw)) as f:
   assert f.getsampwidth()==2 and f.getnchannels()==1
   rate=f.getframerate();data=array.array('h',f.readframes(f.getnframes()))
  voiced=[i for i,v in enumerate(data) if abs(v)>90];assert voiced
  data=data[max(0,voiced[0]-int(rate*.03)):min(len(data),voiced[-1]+int(rate*.08)+1)]
  peak=max(map(abs,data));gain=min(2.0,10**(-6/20)*32768/peak)
  data=array.array('h',(round(v*gain) for v in data))
  with wave.open(str(path),'wb') as f:
   f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(data.tobytes())
 peak=max(map(abs,data));rows.append({'key':key,'hero':hero,'trigger':trigger,'text':text,'file':path.name,'speaker_index':speaker,'length_scale':speed,'duration_seconds':len(data)/rate,'sample_rate_hz':rate,'channels':1,'bits_per_sample':16,'peak_dbfs':20*math.log10(peak/32768),'clipped_samples':sum(abs(v)>=32767 for v in data),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
manifest={'schema_version':1,'version':'VO-01-prototype-v3-piper-seeded','random_seed':1710,'onnxruntime_version':importlib.metadata.version('onnxruntime'),'source':'scripts/generate-hero-voice-prototype.py','source_sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),'method':'Offline Piper neural TTS; edge trim and peak scaling; no uploaded art, paid service, copied game recording or named actor imitation. One model speaker/speed for each hero pair.','engine':{'name':'piper-tts','version':importlib.metadata.version('piper-tts'),'license':'GPL-3.0','bundled_in_app':False,'source':'https://github.com/OHF-Voice/piper1-gpl'},'model':{'name':'en_US-libritts-high','sha256':MODEL_SHA,'config_sha256':hashlib.sha256(pathlib.Path(str(args.model)+'.json').read_bytes()).hexdigest(),'source':'https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_US/libritts/high','declared_repository_license':'MIT','training':'from scratch on train-clean-360, per model card','dataset':'LibriTTS (Zen et al., 2019)','dataset_license':'CC BY 4.0','dataset_source':'https://www.openslr.org/60/'},'quality':'Prototype TTS; expression, casting, listening quality and formal release review Pending. Not actor-quality approval.','rights':'Source provenance and attribution retained; generated candidate supplied with CC BY 4.0 attribution as a conservative reuse condition. No claim of comprehensive commercial or personality-rights clearance. See CREDITS.md. Apple System Voice exports are excluded.','assets':rows}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2));print(json.dumps(rows,indent=2))
