#!/usr/bin/env python3
"""Offline CC0 sample processing for PRESENT-01, no synthesis or runtime TTS.
Retains raw samples, isolated layers, cues, processing manifest and dry previews.
"""
import array
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess
import wave
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'assets/candidates/present-01'
RAW = PACK / 'audio/raw'
STEMS = PACK / 'audio/stems'
OUT = PACK / 'audio/cues'
RESOURCE = ROOT / 'ios/TacticalGo/PresentationLab'
RATE = 44100
for folder in [RAW, STEMS, OUT, RESOURCE]:
    folder.mkdir(parents=True, exist_ok=True)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def decode(path, filters='anull'):
    pcm = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path),
        '-af', filters, '-ac', '1', '-ar', str(RATE), '-f', 'f32le', '-'])
    values = array.array('f'); values.frombytes(pcm)
    return list(values)

def write(path, values, target_rms=None):
    values = list(values)
    rms = math.sqrt(sum(x*x for x in values) / len(values))
    peak = max(abs(x) for x in values)
    gain = min(0.55 / max(peak, 1e-9), 10**(target_rms/20)/max(rms, 1e-9)) if target_rms else 1
    values = [x*gain for x in values]
    stereo = array.array('h')
    for x in values:
        # Every output has a short edge fade. No discontinuous edit boundaries.
        stereo.extend([round(max(-1,min(1,x))*32767)]*2)
    with wave.open(str(path), 'wb') as f:
        f.setparams((2, 2, RATE, 0, 'NONE', 'not compressed')); f.writeframes(stereo.tobytes())
    return {'file': str(path.relative_to(ROOT)), 'sha256': sha(path), 'frames': len(values),
        'duration': len(values)/RATE, 'sample_rate': RATE, 'channels': 2,
        'peak_dbfs': 20*math.log10(max(abs(x) for x in values)),
        'rms_dbfs': 20*math.log10(math.sqrt(sum(x*x for x in values)/len(values))),
        'dc': sum(values)/len(values), 'start_sample': values[0], 'end_sample': values[-1],
        'gain': gain}

def sample(pack, name, length, filters, reverse=False):
    with zipfile.ZipFile(PACK/'sources'/f'kenney-{pack}.zip') as z:
        dest = RAW/name; dest.write_bytes(z.read('Audio/'+name))
    values = decode(dest, filters)
    if reverse: values.reverse()
    n = round(length*RATE)
    values = (values+[0.0]*n)[:n]
    edge = round(.005*RATE)
    for i in range(n):
        values[i] *= min(1, i/edge, (n-1-i)/edge)
    return values, {'source': str(dest.relative_to(ROOT)), 'sha256': sha(dest),
        'pack': pack, 'length': length, 'ffmpeg_filter': filters, 'reverse': reverse}

specs = [
    ('charge-cloth', 'rpg-audio', 'cloth1.ogg', .20, 'highpass=f=250,lowpass=f=4200', False),
    ('charge-crystal', 'impact-sounds', 'impactGlass_light_000.ogg', .20, 'highpass=f=700,lowpass=f=6500', True),
    ('release-air', 'rpg-audio', 'knifeSlice.ogg', .30, 'highpass=f=450,lowpass=f=7000', False),
    ('land-wood', 'impact-sounds', 'impactWood_light_000.ogg', .18, 'highpass=f=100,lowpass=f=2500', False),
    ('land-crystal', 'impact-sounds', 'impactGlass_light_002.ogg', .18, 'highpass=f=1200,lowpass=f=7000', False),
    ('capture-crystal', 'impact-sounds', 'impactGlass_light_004.ogg', .18, 'highpass=f=500,lowpass=f=6000', False),
]
layers = {}; sources = []; files = []
for name, pack, filename, length, filters, reverse in specs:
    samples, metadata = sample(pack, filename, length, filters, reverse)
    # Scale layers independently before cue mixing; they remain inspectable.
    peak = max(abs(x) for x in samples)
    samples = [x*.25/max(peak, 1e-9) for x in samples]
    layers[name] = samples; sources.append({'id': name, **metadata})
    files.append(write(STEMS/(name+'.wav'), samples))

recipes = {
    'p-charge': [('charge-cloth', .45), ('charge-crystal', .7)],
    'p-release': [('release-air', 1)],
    'p-land': [('land-wood', .75), ('land-crystal', .65)],
    'p-capture': [('capture-crystal', .75)],
}
for key, recipe in recipes.items():
    n = max(len(layers[name]) for name, weight in recipe)
    samples = [sum(layers[name][i]*weight if i < len(layers[name]) else 0 for name, weight in recipe) for i in range(n)]
    files.append(write(OUT/(key+'.wav'), samples, -25 if key == 'p-charge' else -23))
    shutil.copy2(OUT/(key+'.wav'), RESOURCE/(key+'.wav'))

for name in ['clean-plate.png','mage-original.png','mage-voice-english.wav']:
    shutil.copy2(PACK/'sources'/name, RESOURCE/name)
assert sha(PACK/'sources/mage-voice-english.wav') == '1cb368035f8d61f1463a9c195e0edb7c37522264dda91a2529a92aef0b7a9950'
assert sha(RESOURCE/'clean-plate.png') == '9a633d497e0ce5baaa1f726312d87b49507df65b1c997c84374fa2f612be294d'

# Dry previews are scheduled from the independently specified A/B sheet.
previews = []
for variant, cues in [('A', [('mage',.28),('place',.54)]),
                      ('B', [('p-charge',0),('p-release',.22),('p-land',.52)])]:
    samples = [0.0]*round(1.5*RATE)
    for key, at in cues:
        path = OUT/(key+'.wav') if key.startswith('p-') else ROOT/'ios/TacticalGo/Audio'/(key+'.wav')
        for i, value in enumerate(decode(path)):
            j = i+round(at*RATE)
            if j < len(samples): samples[j] += value*.65
    assert max(abs(x) for x in samples) < .95
    previews.append(write(PACK/'audio'/(variant+'-sfx-preview.wav'), samples))

overlap = []
for voice in [False, True]:
    samples = [0.0]*round(3.1*RATE) # Existing victory cue lasts 2.15s after .70.
    cues = [('p-charge',0,.65),('p-release',.22,.65),('p-land',.52,.65),('p-capture',.52,.65),('victory',.7,.65)]
    if voice: cues += [('mage-voice-english',.1,.55)]
    for key, at, volume in cues:
        path = RESOURCE/(key+'.wav') if key.startswith('p-') or key == 'mage-voice-english' else ROOT/'ios/TacticalGo/Audio'/(key+'.wav')
        for i, value in enumerate(decode(path)):
            j = i+round(at*RATE)
            if j < len(samples): samples[j] += value*volume
    assert max(abs(x) for x in samples) < .95
    name = 'B-capture-voice-preview.wav' if voice else 'B-capture-preview.wav'
    overlap.append(write(PACK/'audio'/name,samples))

manifest = {'status': 'candidate_owner_listening_pending',
    'rights': {'Kenney': 'CC0, original License.txt retained in sources',
               'voice': 'Existing pinned Qwen VoiceDesign, no reference voice; source manifest retained; owner acceptance pending',
               'art': 'Existing TacticalGo candidate; generation record retained; owner acceptance separate'},
    'sample_origin_claim': 'Licensed audio samples; no claim these were physically recorded foley',
    'sources': sources, 'recipes': recipes, 'outputs': files, 'dry_previews': previews, 'overlap_previews': overlap,
    'ffmpeg_version': subprocess.check_output(['ffmpeg','-version'],text=True).splitlines()[0],
    'resources': [{'file':p.name,'sha256':sha(p)} for p in sorted(RESOURCE.iterdir()) if p.is_file()]}
(PACK/'audio/manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'cues':len(recipes),'layers':len(layers),'previews':len(previews),'resources':len(manifest['resources'])}))
