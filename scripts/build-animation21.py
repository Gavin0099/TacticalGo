"""Export authored visual fixtures and actual native timeline constants, not Domain outcomes."""
from pathlib import Path
import re,json,hashlib
root=Path(__file__).resolve().parents[1]
source=(root/'swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionPresentation.swift').read_text(encoding='utf-8')
timings={}
for cases,values in re.findall(r'case ([^\n]+?): timing = \(([^)]+)\)',source):
    numbers=[float(x) for x in values.split(',')]
    for name in re.findall(r'\.(\w+)',cases): timings[name]=dict(zip(['release','moveStart','arrival','captureStart','duration'],numbers))
fixtures=[
 {'id':'bastion','action':'castBastion','hero':'warrior','title':'築壘','icon':2,'kind':'place','origin':[4,4],'placements':[[3,4],[5,4]],'intent':'雙兵落地壓縮，短暫停住後回彈'},
 {'id':'reformation','action':'castReformation','hero':'warrior','title':'戰線重整','icon':3,'kind':'move','origin':[4,5],'transfers':[{'from':[4,6],'to':[5,5],'owner':'black','kind':'soldier'},{'from':[5,6],'to':[6,6],'owner':'black','kind':'soldier'}],'intent':'兩兵調度後壓實；不投射新增護盾'},
 {'id':'magic','action':'castMagicHand','hero':'mage','title':'魔法之手','icon':4,'kind':'move','origin':[4,4],'transfers':[{'from':[5,4],'to':[5,3],'owner':'white','kind':'soldier'}],'intent':'先托住棋子，再推動、接觸和釋放'},
 {'id':'double','action':'castDoublePull','hero':'mage','title':'雙重牽引','icon':5,'kind':'move','origin':[4,4],'transfers':[{'from':[4,5],'to':[5,5],'owner':'black','kind':'soldier'},{'from':[4,3],'to':[3,3],'owner':'white','kind':'soldier'}],'intent':'雙手分別連到兩兵；保留兩方身份'},
 {'id':'swap','action':'castSwap','hero':'rogue','title':'換位','icon':6,'kind':'swap','origin':[4,4],'transfers':[{'from':[4,4],'to':[5,4],'owner':'black','kind':'hero'},{'from':[5,4],'to':[4,4],'owner':'white','kind':'soldier'}],'intent':'兩條相反弧線，避免在中心疊成一團'},
 {'id':'chain','action':'castChainSwap','hero':'rogue','title':'連鎖換位','icon':7,'kind':'chain','origin':[4,4],'middle':[5,4],'transfers':[{'from':[4,4],'to':[5,3],'owner':'black','kind':'hero'},{'from':[5,4],'to':[4,4],'owner':'white','kind':'soldier','first':True},{'from':[5,3],'to':[5,4],'owner':'white','kind':'soldier'}],'intent':'先完成第一組交換，再突入第二組'},
 {'id':'offering','action':'castOffering','hero':'priest','title':'奉獻','icon':8,'kind':'offering','origin':[3,5],'sacrifice':[4,5],'intent':'己兵在原點向上消散，留下可讀空點'},
]
for f in fixtures:
    f.update(timings[f['action']]);f.setdefault('placements',[]);f.setdefault('transfers',[])
paths=['swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionPresentation.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionFeedback.swift','ios/TacticalGo/ExpansionLabView.swift','ios/TacticalGo/ExpansionSpellEffects.swift','swift/TacticalGoCore/Sources/TacticalGoContent/ExpansionPractice.swift']
result={'evidence':'authored browser motion study, not executed Domain receipts','advanced_reference':'ExpansionPractice coordinates; basic specimens are independently authored visual examples','native_timeline_extracted':True,'fixtures':fixtures,'source_sha256':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in paths}}
(root/'tools/animation-21/fixtures.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Exported seven visual fixtures and source timeline constants')
