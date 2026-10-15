#!/usr/bin/env python3
"""Two English casting takes; offline asset generation, not acting approval."""
import argparse,hashlib,json,pathlib,time,wave,importlib.metadata
import numpy as np
import mlx.core as mx
from mlx_audio.tts.utils import load_model
ROOT=pathlib.Path(__file__).resolve().parents[1]
REVISION='5c390979e4b93af5f2932f90742ca99c7dd04687'
CAST={
 'rogue':('Too slow!',20261024,'A young adult agile fantasy rogue with a light husky midrange voice. Natural fluent English, playful confidence, a sly smile and clear dry studio recording. ',[
  ('A','A quick teasing challenge while deftly stepping sideways. Stress TOO, connect the two words, finish with a crisp falling SLOW. Not whispering, no narration, no extra words.'),
  ('B','A bold nimble battlefield taunt on an unexpected position exchange, projecting clearly with a tiny breathy grin. A snappy TOO and a decisive SLOW, real character energy, no evil laugh, not whispering or narrating, no extra words.')]),
 'priest':('Stay with me!',20261026,'A young adult female fantasy healer, clear warm natural midrange voice, compassionate and determined. Natural fluent English, dry close studio recording. ',[
  ('A','A reassuring protective command to an injured ally. Connected natural words, warm emphasis on STAY and ME, resolute falling ending, not a narrator, no extra words.'),
  ('B','An urgent heartfelt call across the battlefield while reaching out to save an ally. Project the voice with gentle strength, strongly stress STAY and ME, no melodrama or breathless whisper, no narration or extra words.')])}
parser=argparse.ArgumentParser();parser.add_argument('--model',type=pathlib.Path,required=True);parser.add_argument('--seed',type=int);parser.add_argument('--only',choices=['rogue-A','rogue-B','priest-A','priest-B']);parser.add_argument('--output',type=pathlib.Path,default=ROOT/'assets/candidates/feel-10/voice');args=parser.parse_args()
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
  seed = CAST[hero][1] + (take == 'B')
  if args.seed is not None:seed=args.seed
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
  gain=min(10**(-18/20)/rms,10**(-3/20)/peak);dry=trimmed*gain;write(target,dry)
  rows.append({'hero':hero,'take':take,'text':text,'instruct':instruct,'seed':seed,'file':target.name,'raw_file':str(raw_path.relative_to(args.output)),'duration_seconds':len(dry)/rate,'sample_rate':rate,'gain':gain,'rms_dbfs':20*np.log10(float(np.sqrt(np.mean(dry**2)))),'peak_dbfs':20*np.log10(float(np.max(np.abs(dry)))),'generation_seconds':time.time()-begin,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'raw_sha256':hashlib.sha256(raw_path.read_bytes()).hexdigest()})
  print('GENERATED',hero,take,rows[-1]['duration_seconds'],'sec',flush=True)
  (args.output/'takes.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
  mx.clear_cache()
manifest={'version':'FEEL-10-English-rogue-priest-cast','status':'audition_only; Owner performance Gate Pending','model':'mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit','model_revision':REVISION,'model_license':'Apache-2.0 as declared by original and converted model','model_sha256':{str(p.relative_to(args.model)):hashlib.sha256(p.read_bytes()).hexdigest() for p in args.model.rglob('*') if p.is_file() and '.cache' not in p.parts},'runtime':{p:importlib.metadata.version(p) for p in ['mlx','mlx-audio','transformers','numpy']},'source':'scripts/generate-expansion-cast-voices.py','source_sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),'offline_inference':True,'reference_audio':None,'paid_service':False,'app_audio_changed':False,'processing':'edge trim + linear gain toward -18dBFS RMS / capped -3dBFS peak; no sound effects/music/pitch/time warping','reproducibility':'seed and source pins retained; cross-process bit identity not yet claimed','assets':rows}
(args.output/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('PILOT GENERATED; expression quality is not automated PASS',flush=True)
