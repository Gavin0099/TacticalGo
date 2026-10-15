#!/usr/bin/env python3
"""Offline A/B from actual native schedules. This does not record native device audio."""
import argparse,array,hashlib,json,math,shutil,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];RATE=44100;SECONDS=3;N=RATE*SECONDS
p=argparse.ArgumentParser();p.add_argument('--baseline',required=True);p.add_argument('--candidate',required=True);p.add_argument('--out',required=True)
a=p.parse_args();out=Path(a.out).resolve();out.mkdir(parents=True,exist_ok=True)
base=json.loads((Path(a.baseline)/'SCHEDULES.json').read_text());candidate=json.loads((Path(a.candidate)/'SCHEDULES.json').read_text())
cache={};sources={}
def run(*args,**kwargs):return subprocess.run(args,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,**kwargs)
def path(key):
    resource='p8-rogue-land' if key=='p8-rogue-land-first' else key
    folder='P08' if key.startswith('p8-') else 'P07' if key.startswith('w7-') else 'P06' if key.startswith('mage-cast-') else 'P05' if key.startswith('p5-') else None
    return ROOT/'ios/TacticalGo'/('PresentationLab/'+folder if folder else 'Audio')/(resource+'.wav')
def pcm(file,phase=None):
    identity=(str(file),phase)
    if identity not in cache:
        args=['ffmpeg','-v','error']+(['-ss',str(phase)] if phase is not None else [])+['-i',str(file)]+(['-t',str(SECONDS)] if phase is not None else [])+['-ac','1','-ar',str(RATE),'-f','f32le','-']
        x=array.array('f');x.frombytes(run(*args).stdout);cache[identity]=x
        sources[str(file.relative_to(ROOT))]=hashlib.sha256(file.read_bytes()).hexdigest()
    return cache[identity]
def mix(record):
    voice=array.array('f',[0])*N;sfx=array.array('f',[0])*N
    for c in record['soundSchedule']:
        is_voice='voice' in c['key'] or c['key'].startswith('mage-cast-')
        x=pcm(path(c['key']));dest=voice if is_voice else sfx;start=round(c['delay']*RATE)
        for i,v in enumerate(x[:N-start]):dest[start+i]+=v*c['actualPlayerGain']
    return voice,sfx
def bgm(record,level):
    result=array.array('f',[0])*N
    if level=='none':return result
    files=['b-normal']+(['b-focus','b-danger'] if level=='danger' else [])
    hero=record['scene'].split('-')[0] in ['warrior','mage','rogue','priest']
    hold=max([record['duration']]+[c['delay']+len(pcm(path(c['key'])))/RATE for c in record['soundSchedule']])
    target=10**(-5/20)
    for name in files:
        x=pcm(ROOT/'ios/TacticalGo/Audio'/(name+'.wav'),phase=8)
        for i,v in enumerate(x[:N]):
            t=i/RATE
            duck=1 if not hero else 1+(target-1)*t/.12 if t<.12 else target if t<=hold else target+(1-target)*min(1,(t-hold)/.75)
            result[i]+=v*.30*duck
    return result
def sum_pcm(*tracks):return array.array('f',(sum(v) for v in zip(*tracks)))
def write(file,x,floating=False):
    assert not file.exists(),file
    run('ffmpeg','-v','error','-f','f32le','-ar',str(RATE),'-ac','1','-i','pipe:0','-c:a','pcm_f32le' if floating else 'pcm_s16le',str(file),input=x.tobytes())
def measure(file):
    r=run('ffmpeg','-hide_banner','-i',str(file),'-af','loudnorm=I=-24:TP=-1:LRA=11:print_format=json','-f','null','-')
    # ffmpeg can append muxer statistics after loudnorm's valid JSON object.
    info,_=json.JSONDecoder().raw_decode('{'+r.stderr.decode().split('{')[-1])
    return dict(lufs=float(info['input_i']),truePeakDBTP=float(info['input_tp']))
def metrics(x):
    peak=max(map(abs,x));rms=math.sqrt(sum(v*v for v in x)/len(x))
    return dict(peakDBFS=20*math.log10(peak),rmsDBFS=20*math.log10(rms),samplesAboveFullScale=sum(abs(v)>1 for v in x))
def speech_ratio(voice,others):
    peak=max(map(abs,voice))
    if peak==0:return None
    active=[i for i,v in enumerate(voice) if abs(v)>max(.02,peak*.10)]
    speech=sum(voice[i]**2 for i in active);bed=sum(others[i]**2 for i in active)
    return 10*math.log10(speech/bed) if bed>0 else None
prep={'p5-conjure','w7-brace','p8-rogue-coil','p8-priest-prayer'}
motion={'p5-push','p8-rogue-dash','p8-priest-bless'}
pre_mon={'p8-slime-coil','p8-wolf-growl'};move_mon={'p8-slime-bounce','p8-wolf-dash'}
pairs=[];checked=0
for before,after in zip(base,candidate):
    assert before['scene']==after['scene'] and before['voicePreference']==after['voicePreference']
    for k in ['action','before','after','beforeAP','afterAP','beforeMana','afterMana','release','moveStart','arrival','duration','soundKeys']:
        assert before[k]==after[k],(before['scene'],k)
    for old,new in zip(before['soundSchedule'],after['soundSchedule']):
        key=new['key'];assert key==old['key'] and new['delay']==old['delay']
        expected=(.20 if after['voicePreference'] else .42) if key in prep else (.26 if after['voicePreference'] else .58) if key in motion else .48 if key in pre_mon else .58 if key in move_mon else old['gain']
        assert abs(new['actualPlayerGain']-expected)<1e-6,(key,new,expected)
        checked+=1
    if before['scene'] not in ['warrior-basic','mage-basic','rogue-advanced','priest-basic','slime-loot','wolf-loot']:continue
    label=before['scene']+('-voiced' if before['voicePreference'] else '-no-voice')
    v0,s0=mix(before);v1,s1=mix(after)
    for background in ['none','normal','danger']:
        music=bgm(before,background);x0=sum_pcm(v0,s0,music);x1=sum_pcm(v1,s1,music)
        name=label+'-'+background
        raw0=out/(name+'-baseline-raw-float.wav');raw1=out/(name+'-candidate-raw-float.wav')
        write(raw0,x0,True);write(raw1,x1,True);m0=measure(raw0);m1=measure(raw1)
        # Equal integrated loudness and at least 3dB true-peak headroom, using only linear gain.
        target=min(m0['lufs'],m1['lufs'],m0['lufs']-3-m0['truePeakDBTP'],m1['lufs']-3-m1['truePeakDBTP'])
        gain0=10**((target-m0['lufs'])/20);gain1=10**((target-m1['lufs'])/20)
        matched0=out/(name+'-baseline-matched.wav');matched1=out/(name+'-candidate-matched.wav')
        passes=[]
        # Short clips can cross loudness gates after attenuation/PCM conversion.
        # Verify achieved loudness and converge downward instead of assuming linearity.
        for attempt in range(4):
            pass0=out/(name+f'-baseline-pass{attempt}.wav');pass1=out/(name+f'-candidate-pass{attempt}.wav')
            write(pass0,array.array('f',(v*gain0 for v in x0)));write(pass1,array.array('f',(v*gain1 for v in x1)))
            check0=measure(pass0);check1=measure(pass1);passes.append(dict(baseline=check0,candidate=check1))
            if abs(check0['lufs']-check1['lufs'])<=.10 and max(check0['truePeakDBTP'],check1['truePeakDBTP'])<=-2.8:break
            target=min(check0['lufs'],check1['lufs'],check0['lufs']-3-check0['truePeakDBTP'],check1['lufs']-3-check1['truePeakDBTP'])
            gain0*=10**((target-check0['lufs'])/20);gain1*=10**((target-check1['lufs'])/20)
        assert abs(check0['lufs']-check1['lufs'])<=.10 and max(check0['truePeakDBTP'],check1['truePeakDBTP'])<=-2.8,(name,check0,check1)
        shutil.copy2(pass0,matched0);shutil.copy2(pass1,matched1)
        pairs.append(dict(scene=before['scene'],voicePreference=before['voicePreference'],background=background,bgmPhaseSeconds=8,bgmMaster=.30,bgmSteadyLayers='all3' if background=='danger' else 'normal1' if background=='normal' else 'none',duration=SECONDS,baseline=dict(raw=str(raw0.relative_to(ROOT)),matched=str(matched0.relative_to(ROOT)),rawMeasurement=m0,rawMetrics=metrics(x0),matchGain=gain0,matchedMeasurement=check0,activeSpeechToSFXAndMusicDB=speech_ratio(v0,sum_pcm(s0,music))),candidate=dict(raw=str(raw1.relative_to(ROOT)),matched=str(matched1.relative_to(ROOT)),rawMeasurement=m1,rawMetrics=metrics(x1),matchGain=gain1,matchedMeasurement=check1,activeSpeechToSFXAndMusicDB=speech_ratio(v1,sum_pcm(s1,music))),targetLUFS=target,matchingPasses=passes))
        print('Rendered equal-LUFS comparison:',name,flush=True)
manifest=dict(method='Offline float summation from actual native AVAudioPlayer schedules/volume; ffmpeg mono44.1k resampling and loudnorm measurement; matched output linear gain only, PCM16. Not a device audio recording.',actualNativeCueGainsChecked=checked,nativeSchedulesCompared=len(base),pairs=pairs,sources=sources,limits=['No listening/intelligibility/phone speaker/AV latency claim','Fixed phase8 normal or steady-danger bed, not reconstructed Core music transition','Fixtures have no captures or terminal cues; peak checks do not cover every legal simultaneous cue','Loudness matching changes whole audition gain; runtime voice gain remains .85 and dry assets unchanged'])
(out/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Complete:',len(pairs),'pairs;',checked,'actual native cue gain checks',flush=True)
