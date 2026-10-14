"""Export contact envelope constants for a Canvas study; does not execute Swift or Domain."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parents[1]
source='swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionContact.swift'
s=(root/source).read_text(encoding='utf-8')
radius=re.search(r'radius:(\d+\.\d+)\+(\d+\.\d+)\*MotionCurves.ease',s)
tail=re.search(r'time < start\+(\d+\.\d+)',s)
fade=re.search(r'ease\(\(u-(\d+\.\d+)\)/(\d+\.\d+)\)',s)
rise=re.search(r'rise:(\d+\.\d+)\*u',s)
assert all([radius,tail,fade,rise])
paths=[source,'ios/TacticalGo/ExpansionContactEffects.swift','ios/TacticalGo/ExpansionSpellEffects.swift',
       'ios/TacticalGo/ExpansionLabView.swift','ios/TacticalGo/PresentationLabView.swift',
       'ios/TacticalGo/IntegratedAudioAudit.swift','ios/TacticalGo.xcodeproj/project.pbxproj']
data={'evidence':'Authored Canvas contact study; current envelope numbers exported, no Swift execution',
      'tail':float(tail[1]),'radius':float(radius[1]),'radiusDelta':float(radius[2]),
      'holdFraction':float(fade[1]),'fadeFraction':float(fade[2]),'rise':float(rise[1]),
      'source_text_sha256_lf':{p:hashlib.sha256((root/p).read_text(encoding='utf-8').encode()).hexdigest() for p in paths}}
out=root/'tools/animation-24';out.mkdir(exist_ok=True,parents=True)
(out/'contact.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print('Exported contact envelope. Swift/native NOT RUN.')
