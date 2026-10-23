from pathlib import Path
import sys, argparse
from collections import Counter, defaultdict
from statistics import median
import hashlib, json

parser=argparse.ArgumentParser()
parser.add_argument("evidence",type=Path)
parser.add_argument("--check",action="store_true")
args=parser.parse_args()
ROOT=args.evidence
def load(p): return json.loads(p.read_text())
def save(name, value):
    if args.check:
        assert load(ROOT/name)==value, f"Published aggregate differs: {name}"
    else:
        (ROOT/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+"\n")
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
CLASSES = ['Warrior','Mage','Rogue','Priest']
PAIRS = [('Warrior','Mage'),('Mage','Warrior'),('Rogue','Priest'),('Priest','Rogue')]

games=[]; traces={}; all_turns=[]; prefixes=[]
for board in [7,9]:
    for one,two in PAIRS:
        ident=f'b{board}-{one}-{two}'; folder=ROOT/'complete-games'/ident
        assert (folder/'summary.json').exists(),f'Incomplete: {ident}'
        g=load(folder/'summary.json'); tr=load(folder/'trace.json')
        assert g['result'] in ['won','drawn']
        assert g['serializedReceiptsVerified'] and g['fullReplayIncludingHistoryEqual']
        assert len(tr['frames'])==g['atomicActions']
        assert len(tr['turns'])==g['turns']
        passes=[bool(t['actions']) and all(a['kind']=='end' for a in t['actions']) for t in tr['turns']]
        assert passes==[t['purePass'] for t in tr['turns']]
        assert sum(passes)==g['purePassTurns']
        g['recordSha256']=digest(folder/'record.json');g['traceSha256']=digest(folder/'trace.json')
        games.append(g);traces[ident]=tr
        for t in tr['turns']:
            t=dict(t,game=ident,boardSize=board)
            all_turns.append(t)

by_class=[]
for board in [7,9]:
    for hero in CLASSES:
        rows=[t for t in all_turns if t['boardSize']==board and t['heroClass']==hero]
        a=lambda t:t['availability']
        by_class.append({'board':board,'hero':hero,'turns':len(rows),
            'heroPresentTurns':sum(a(t)['heroPresent'] for t in rows),
            'basicLegalAtTurnStart':sum(a(t)['basicLegal'] for t in rows),
            'advancedLegalAtTurnStart':sum(a(t)['advancedLegal'] for t in rows),
            'anySkillLegalAtTurnStart':sum(a(t)['basicLegal'] or a(t)['advancedLegal'] for t in rows),
            'skillUsedTurns':sum(t['usedBasic'] or t['usedAdvanced'] for t in rows),
            'basicUsedTurns':sum(t['usedBasic'] for t in rows),
            'advancedUsedTurns':sum(t['usedAdvanced'] for t in rows),
            'skillAndSoldierTurns':sum(t['pattern'] in ['skill+soldier','soldier+skill'] for t in rows),
            'purePassTurns':sum(t['purePass'] for t in rows),
            'fullManaPurePassTurns':sum(t['purePass'] and t['mana']==6 for t in rows),
            'patterns':dict(Counter(t['pattern'] for t in rows))})

def liberties(diagram,player):
    rows=diagram.splitlines(); n=len(rows); own=set('xXH' if player==0 else 'oOQ')
    commander='X' if player==0 else 'O'
    start=next(((x,y) for y in range(n) for x in range(n) if rows[y][x]==commander),None)
    if start is None:return 0
    group={start}; queue=[start]; empty=set()
    for x,y in queue:
        for xx,yy in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
            if not (0<=xx<n and 0<=yy<n):continue
            if rows[yy][xx]=='.':empty.add((xx,yy))
            elif rows[yy][xx] in own and (xx,yy) not in group:group.add((xx,yy));queue.append((xx,yy))
    return len(empty)

capped=load(ROOT/'capped-cohort.json')
mapping={'7-w-m':'b7-Warrior-Mage','7-m-w':'b7-Mage-Warrior','7-r-p':'b7-Rogue-Priest',
         '7-p-r':'b7-Priest-Rogue','9-w-m':'b9-Warrior-Mage'}
for fixture,ident in mapping.items():
    original=[t for t in capped['turns'] if t['game']==fixture]
    actual=traces[ident]['turns']; frames=traces[ident]['frames']
    first_frames={}
    for f in frames:first_frames.setdefault(f['turn'],f)
    mismatches=[]
    for i,t in enumerate(original):
        if i>=len(actual):mismatches.append({'turn':i,'field':'missing'});break
        a=actual[i];before=first_frames[i]['before']
        kinds=[{'soldier':'place','summon':'summon','end':'pass','hunt':'hunt'}.get(m['kind'],'skill') for m in a['actions']]
        checks={'ply':a['ply']==t['ply'],'actor':a['player']==t['actor'],
            'mana':a['mana']==t['mana'],'selectedKinds':kinds==t['selectedKinds'],
            'myLiberties':liberties(before['board'],a['player'])==t['myCommanderLiberties'],
            'enemyLiberties':liberties(before['board'],1-a['player'])==t['enemyCommanderLiberties']}
        mismatches += [{'turn':i,'field':k} for k,ok in checks.items() if not ok]
    prefixes.append({'cappedFixture':fixture,'completeGame':ident,'turnsChecked':len(original),
                     'matched':not mismatches,'mismatches':mismatches[:12]})

samples=[];audit_samples=[]
for board in [7,9]:
    for hero in CLASSES:
        rows=sorted([t for t in all_turns if t['boardSize']==board and t['heroClass']==hero],key=lambda t:(t['ply'],t['game']))
        tests=[('first-observed-skill-soldier',lambda t:t['pattern'] in ['skill+soldier','soldier+skill']),
               ('first-ordinary-pair-with-legal-skill',lambda t:t['pattern']=='soldier+soldier' and (t['availability']['basicLegal'] or t['availability']['advancedLegal']))]
        for reason,predicate in tests:
            t=next((t for t in rows if predicate(t)),None)
            if t is not None:samples.append({'game':t['game'],'turn':t['index'],'ply':t['ply'],'hero':hero,'reason':reason})
        for t in rows:
            ts=traces[t['game']]['turns'];i=t['index']
            if t['purePass'] and 21<=t['ply']<=95 and i+2<len(ts) and all(x['purePass'] for x in ts[i:i+3]):
                audit_samples.append({'game':t['game'],'turn':i,'ply':t['ply'],'hero':hero});break

summary={'sourceHead':'3e48a5ec1869168a9d91c074d7b11419cfb1ac1c',
    'scope':'four ordered pairs, matched 7x7/9x9, one deterministic official-opening Standard/Baseline path per pair/size',
    'completedGames':len(games),'games':games,'byClass':by_class,
    'totals':{'turns':len(all_turns),'atomicActions':sum(g['atomicActions'] for g in games),
        'coreWins':sum(g['result']=='won' for g in games),'coreDraws':sum(g['result']=='drawn' for g in games),
        'purePassTurns':sum(t['purePass'] for t in all_turns),
        'fullManaPurePassTurns':sum(t['purePass'] and t['mana']==6 for t in all_turns),
        'skillUsedTurns':sum(t['usedBasic'] or t['usedAdvanced'] for t in all_turns),
        'skillAndSoldierTurns':sum(t['pattern'] in ['skill+soldier','soldier+skill'] for t in all_turns)},
    'prefixVerification':prefixes,'naturalProbeSelection':samples,'passAuditSelection':audit_samples,
    'timing':{'observedPlannerMedianSeconds':median(t['seconds'] for t in all_turns),
              'scope':'Mac under ambient load, not an iPhone performance gate'},
    'limits':['Four pairings do not estimate a population-wide win/draw rate or class balance',
              'Skill legality and use do not prove skill value',
              'Natural probe selection is earliest by ply, not best-looking result',
              'Only selected late pass positions will be diagnosed; incomplete search remains unknown',
              'No P1 dominance, human understanding, fun or replay willingness claim']}
save('complete-analysis.json',summary)
save('probe-selection.json',samples)
save('pass-audit-selection.json',audit_samples)
print(json.dumps({'completeGames':len(games),'totals':summary['totals'],'prefixMatches':[p['matched'] for p in prefixes],
                  'selectedProbes':len(samples),'selectedPassAudits':len(audit_samples)},ensure_ascii=False))
