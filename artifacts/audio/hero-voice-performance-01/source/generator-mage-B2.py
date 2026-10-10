#!/usr/bin/env python3
"""Two-line offline performance audition. Does not alter App audio or accept acting quality."""
import argparse,hashlib,json,pathlib,time,wave,importlib.metadata
import numpy as np
import mlx.core as mx
from mlx_audio.tts.utils import load_model
ROOT=pathlib.Path(__file__).resolve().parents[1]
REVISION='5c390979e4b93af5f2932f90742ca99c7dd04687'
CAST={
 'warrior':('Hold the line!',20261010,'A young adult male fantasy guardian, youthful clear midrange voice with a warm slightly rough edge. Natural English, animated game character, clean dry studio recording. ',[
  ('A','A firm urgent battlefield command to allies. Breath-supported projecting call, strongly stress HOLD and LINE, connected words and a decisive falling ending. Brave and protective, not enraged. No narration.'),
  ('B','Lead allies with a short determined rallying shout. Give HOLD an assertive attack, lightly link the, then land LINE with conviction. Energetic and confident, no gravelly monster growl or extra words.')]),
 'mage':('Off you go!',20261011,'A young adult female fantasy mage, clear bright midrange voice, warm smile and a lightly mischievous personality. Natural English, animated game character, clean dry studio recording. ',[
  ('A','Speak one short playful phrase with a smiling, cheeky tone and lively rhythm. Clear spoken words, not sung or whispered. A light mischievous spellcasting quip.'),
  ('B','Speak the supplied three words once, with a bright mischievous smile and a quick bouncy spoken rhythm. Off lightly springs forward, you connects, go lands playfully. Clear speech, not singing. Do not add a laugh, chuckle, exclamation, greeting or other words.')])}
parser=argparse.ArgumentParser();parser.add_argument('--model',type=pathlib.Path,required=True);parser.add_argument('--only',choices=['warrior-A','warrior-B','mage-A','mage-B']);parser.add_argument('--output',type=pathlib.Path,default=ROOT/'artifacts/audio/hero-voice-performance-01');args=parser.parse_args()
args.output.mkdir(parents=True,exist_ok=True);raw=args.output/'raw';raw.mkdir(exist_ok=True)
assert importlib.metadata.version('mlx-audio')=='0.5.8'
model_config=json.loads((args.model/'config.json').read_text());assert model_config['tts_model_type']=='voice_design'
mx.set_cache_limit(256*1024*1024)
print('Loading local model; no reference voice or remote inference',flush=True)
model=load_model(str(args.model));rows=[]
for hero,(text,seed,identity,takes) in CAST.items():
 for take,direction in takes:
  if args.only and args.only != hero+'-'+take:continue
  target=args.output/f'{hero}-{take}-dry.wav';assert not target.exists(),'Preserve previous takes; use another output directory'
  if args.only == 'mage-A':seed=20261015
  if args.only == 'mage-B':seed=20261016
  mx.random.seed(seed);begin=time.time();pieces=[];rate=None
  instruct=identity+direction
  for result in model.generate(text=text,instruct=instruct,lang_code='English',temperature=.7,top_p=.9,top_k=40,max_tokens=80,verbose=False):
   mx.eval(result.audio);pieces.append(np.asarray(result.audio).reshape(-1));rate=result.sample_rate
  audio=np.concatenate(pieces);assert rate==24000 and np.all(np.isfinite(audio))
  def write(path,samples):
   assert np.max(np.abs(samples))<1,'Clipping before PCM encoding'
   with wave.open(str(path),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(np.round(samples*32767).astype('<i2').tobytes())
  raw_path=raw/f'{hero}-{take}-unprocessed.wav';write(raw_path,audio)
  # Edge trim and linear gain only: no pitch/time warping, reverb, compression or effects.
  active=np.flatnonzero(np.abs(audio)>.002)
  assert len(active)>0
  begin_i=max(0,int(active[0])-int(rate*.03));end_i=min(len(audio),int(active[-1])+int(rate*.12))
  trimmed=audio[begin_i:end_i];rms=float(np.sqrt(np.mean(trimmed**2)));peak=float(np.max(np.abs(trimmed)))
  gain=min(10**(-20/20)/rms,10**(-3/20)/peak);dry=trimmed*gain;write(target,dry)
  rows.append({'hero':hero,'take':take,'text':text,'instruct':instruct,'seed':seed,'file':target.name,'raw_file':str(raw_path.relative_to(args.output)),'duration_seconds':len(dry)/rate,'sample_rate':rate,'gain':gain,'rms_dbfs':20*np.log10(float(np.sqrt(np.mean(dry**2)))),'peak_dbfs':20*np.log10(float(np.max(np.abs(dry)))),'generation_seconds':time.time()-begin,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'raw_sha256':hashlib.sha256(raw_path.read_bytes()).hexdigest()})
  print('GENERATED',hero,take,rows[-1]['duration_seconds'],'sec',flush=True)
  (args.output/'takes.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
  mx.clear_cache()
manifest={'version':'VO-PERF-01-Qwen-VoiceDesign-pilot','status':'audition_only; Owner performance Gate Pending','model':'mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit','model_revision':REVISION,'model_license':'Apache-2.0 as declared by original and converted model','model_sha256':{str(p.relative_to(args.model)):hashlib.sha256(p.read_bytes()).hexdigest() for p in args.model.rglob('*') if p.is_file() and '.cache' not in p.parts},'runtime':{p:importlib.metadata.version(p) for p in ['mlx','mlx-audio','transformers','numpy']},'source':'scripts/generate-hero-voice-performance-pilot.py','source_sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),'offline_inference':True,'reference_audio':None,'paid_service':False,'app_audio_changed':False,'processing':'edge trim + linear gain toward -20dBFS RMS / capped -3dBFS peak; no sound effects/music/pitch/time warping','reproducibility':'seed and source pins retained; cross-process bit identity not yet claimed','assets':rows}
(args.output/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('PILOT GENERATED; expression quality is not automated PASS',flush=True)
