"""Export source-art cutout polygons and authored Swift pose keys; no raster edits or Domain evaluation."""
from pathlib import Path
import re,json,hashlib
r=Path(__file__).resolve().parents[1]
def read(p): return (r/p).read_text(encoding='utf-8')
def points(s): return [[float(a),float(b)] for a,b in re.findall(r'\((-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)\)',s)]
def scalar(s):
    s=s.strip().replace('timing.anticipationEnd','0.18').replace('timing.release','0.30').replace('timing.moveStart','0.46').replace('timing.arrival','0.68').replace('timing.recoveryEnd','1.08')
    m=re.fullmatch(r'(-?\d+(?:\.\d+)?)\s*([+-])\s*(\d+(?:\.\d+)?)',s)
    if m: return float(m[1])+(1 if m[2]=='+' else -1)*float(m[3])
    return float(s)
def pose_table(s,variant=0,weighted=False):
    defs={'.rest':{}}
    for name,body in re.findall(r'let (\w+)\s*=\s*Self\(([^)]*)\)',s):
        values={}
        for pair in body.split(','):
            if not pair.strip(): continue
            k,v=pair.split(':',1)
            if 'weighted' in v: v=v.split('?')[1].split(':')[0 if weighted else 1]
            values[k.strip()]=scalar(v)
        defs[name]=values
    keytext=s.split('let keys:',1)[1].split('=',1)[1]
    keytext=re.split(r'func sample|var p\s*=|var pose\s*=',keytext)[0]
    tables=re.findall(r'\[([^\]]+)\]',keytext)
    table=tables[variant]
    keys=[[scalar(t),defs[name]] for t,name in re.findall(r'\(([^,()]+),\s*([.\w]+)\)',table)]
    assert keys and all(a[0]<b[0] for a,b in zip(keys,keys[1:]))
    lag={k:float(v) for k,v in re.findall(r'(?:p|pose)\.(\w+)\s*=\s*sample\(max\(0,\s*(?:time|t)\s*-\s*([\d.]+)\)\)\.\w+',s)}
    return {'keys':keys,'lag':lag}
wr=read('ios/TacticalGo/WarriorBodyView.swift');polys=[points(s) for s in re.findall(r'HeroCutoutPolygon\(\[(.*?)\]\)',wr,re.S)]
assert len(polys)==7
rigs={'warrior':{'head':polys[0],'held':polys[1],'shield':polys[2],'cloth':polys[3],'backing':[polys[1],polys[2],polys[4]],'seams':polys[5:]}}
for k,x,y in re.findall(r'(\w+)Pivot:\s*CGPoint\(x:(\d+),y:(\d+)\)',wr): rigs['warrior'][k+'Pivot']=[float(x),float(y)]
er=read('ios/TacticalGo/ExpansionHeroBody.swift')
for hero in ['rogue','priest']:
    block=er.split('static let '+hero+' = Self(',1)[1].split('bodyPivot:',1)[0]
    rig={k:points(p) for k,p in re.findall(r'(head|hand|book|cloth):\.init\(\[(.*?)\]\)',block,re.S)}
    for group,end in [('backing','seams'),('seams','headPivot')]:
        value=block.split(group+':[',1)[1].split(end+':',1)[0]
        rig[group]=[points(v) for v in re.findall(r'\.init\(\[(.*?)\]\)',value,re.S)]
    for k,x,y in re.findall(r'(\w+)Pivot:\s*CGPoint\(x:(\d+),y:(\d+)\)',block):rig[k+'Pivot']=[float(x),float(y)]
    tail=er.split('static let '+hero+' = Self(',1)[1]
    x,y=re.search(r'bodyPivot:CGPoint\(x:(\d+),y:(\d+)\)',tail).groups();rig['bodyPivot']=[float(x),float(y)];rig.setdefault('bookPivot',[0,0]);rigs[hero]=rig
mr=read('ios/TacticalGo/PresentationMageBody.swift').split('private struct MageMask:',1)[1].split('#endif',1)[0]
rigs['mage']={k:points(v) for k,v in re.findall(r'static let (\w+) = Self\(points:\s*\[(.*?)\]',mr,re.S)}
rigs['mage']['held']=points(re.search(r'private static let held:.*?=\s*\[(.*?)\]',mr,re.S)[1])
def tables(prefix=''):
    def src(p): return read(prefix+p)
    w=src('swift/TacticalGoCore/Sources/TacticalGoMotion/WarriorPresentationPlan.swift').split('public static func skill(',1)[1].split('/// Consumes',1)[0]
    m=src('swift/TacticalGoCore/Sources/TacticalGoMotion/MagePerformance.swift').split('private static func contactCast(',1)[1]
    e=src('swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionHeroPose.swift');rogue=e.split('public static func rogue(',1)[1].split('public static func priest(',1)[0];priest=e.split('public static func priest(',1)[1]
    return {'warrior':pose_table(w,0,True),'mage':pose_table(m),'rogue':pose_table(rogue,1 if not prefix else 0),'chain':pose_table(rogue),'priest':pose_table(priest,1 if not prefix else 0),'offering':pose_table(priest)}
data={'source':'Swift polygons and keyed poses, Canvas compositing still requires native comparison','rigs':rigs,'before':tables('artifacts/animation-22/baseline/'),'after':tables()}
(r/'tools/animation-22/rigs.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
fixtures=json.loads(read('tools/animation-21/fixtures.json'));fixtures['evidence']='AV22 browser layered motion study; not native gameplay';fixtures['source_sha256']={p:hashlib.sha256((r/p).read_bytes()).hexdigest() for p in ['ios/TacticalGo/ExpansionSpellEffects.swift','ios/TacticalGo/ExpansionLabView.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionHeroPose.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionFeedback.swift']}
(r/'tools/animation-22/fixtures.json').write_text(json.dumps(fixtures,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Exported four cutout rigs and before/after native pose key tables')
