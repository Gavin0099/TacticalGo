"""Native SVG storyboard with existing embedded character assets; no new art generation."""
from pathlib import Path
import base64
ROOT=Path(__file__).resolve().parents[1]
def image_uri(name):
    return 'data:image/png;base64,'+base64.b64encode((ROOT/'tokens'/name).read_bytes()).decode('ascii')
def svg(role,phase):
    art=image_uri('A-'+role+('-v02.png' if role=='rogue' else '-v01.png'))
    hero_x=90 if role!='rogue' or phase<2 else 120
    enemy_x=120 if role!='rogue' or phase<2 else 90
    s=['<svg viewBox="0 0 210 210" role="img" aria-label="局部棋盤動作分鏡">', '<defs><linearGradient id="wood" x2="1" y2="1"><stop stop-color="#f0d9aa"/><stop offset="1" stop-color="#cea065"/></linearGradient></defs>', '<path d="M18 32H192V181Q105 199 18 181Z" fill="#80512c"/>','<rect x="18" y="24" width="174" height="158" rx="9" fill="url(#wood)" stroke="#a9783f" stroke-width="4"/>']
    for i in range(5):
        p=30+i*30
        s.append(f'<path d="M30 {p+20}H150M{p} 50V170" stroke="#987642" stroke-width=".8"/>')
    s.append(f'<ellipse cx="{hero_x+3}" cy="119" rx="19" ry="7" fill="#674b3633"/><ellipse cx="{hero_x}" cy="114" rx="18" ry="9" fill="#fff6e4" stroke="#746347" stroke-width="2"/><image href="{art}" x="{hero_x-23}" y="69" width="46" height="46"/>')
    if phase==0:s.append(f'<circle cx="{hero_x}" cy="110" r="22" fill="none" stroke="#28748a" stroke-width="2"/>')
    def stone(x,y,fill):return f'<ellipse cx="{x+2}" cy="{y+6}" rx="12" ry="5" fill="#58412a33"/><circle cx="{x}" cy="{y}" r="11" fill="{fill}" stroke="#665944" stroke-width="1.2"/>'
    def target(x,y):return f'<path d="M{x} {y-16} {x+16} {y} {x} {y+16} {x-16} {y}Z" fill="none" stroke="#755091" stroke-width="2" stroke-dasharray="5 3"/>'
    if role=='warrior':
        if phase<2:s.extend([target(60,110),target(120,110)])
        else:s.extend([stone(60,110,'#fff7e6'),stone(120,110,'#fff7e6')])
        if phase==1:s.append('<path d="M77 81 90 71 103 81 103 99 90 110 77 99Z" fill="#84a8c480" stroke="#f3e7ad" stroke-width="2"/>')
    elif role=='mage':
        y=110 if phase<2 else 125 if phase==2 else 140
        s.append(stone(120,y,'#26343d'))
        s.append('<path d="M142 111V143L136 136M142 143 148 136" fill="none" stroke="#704b96" stroke-width="2.5"/>')
        if phase<2:s.append(target(120,140))
        if phase==1:s.append('<path d="M132 77V69Q137 64 139 70V82L145 83Q149 86 146 94L135 104 126 99 120 88Q118 83 124 84L132 89Z" fill="#ac8fcc80" stroke="#8462ae" stroke-width="2"/>')
        if phase==3:s.append('<circle cx="120" cy="110" r="7" fill="#f7f3e4" stroke="#28748a" stroke-width="2"/><path d="M120 106V114M116 110H124" stroke="#28748a" stroke-width="2"/>')
    else:
        s.append(stone(enemy_x,110,'#26343d'))
        if phase<3:s.append('<path d="M90 80Q108 67 124 80L119 73M124 80 116 81M120 143Q102 154 86 142L93 147M86 142 94 140" fill="none" stroke="#8c6b36" stroke-width="2.5"/>')
        if phase==1:s.append('<path d="M72 85 81 68 84 90Z" fill="#fff2ae"/>')
    s.append('</svg>')
    return ''.join(s)
rows=[('warrior','戰士 · 築壘',['預覽 · 兩個空點','0–90 ms · 盾前傾','90–230 ms · 雙子出現','230–350 ms · 落定']),('mage','法師 · 魔法之手',['預覽 · 起點與方向','0–80 ms · 魔法手勢','80–300 ms · 推一格','300–400 ms · 原位空點']),('rogue','盜賊 · 換位',['預覽 · 兩個交換點','0–70 ms · 短刃亮相','70–250 ms · 對向交換','250–330 ms · 新位置'])]
html='''<!doctype html><html lang="zh-Hant"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>TacticalGo 動畫分鏡</title><style>*{box-sizing:border-box}body{margin:0;background:#f5f0e4;color:#303c3b;font:14px/1.6 system-ui,"Microsoft JhengHei",sans-serif}main{max-width:1060px;margin:auto;padding:26px}h1{font-size:28px;margin:4px 0}h2{font-size:19px}.eyebrow{font-size:11px;letter-spacing:2px;color:#426965}p{color:#647069}.row{border-top:1px solid #d4c9b3;margin:24px 0;padding-top:14px}.frames{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}figure{margin:0;background:#fffaf0;border:1px solid #d4c9b3;border-radius:14px;overflow:hidden}svg{display:block;width:100%}figcaption{font-size:12px;text-align:center;padding:8px;border-top:1px solid #ded5c3}.note{border-left:3px solid #aa8751;padding:10px 13px;background:#eee4cf;font-size:12px}a{color:#426965}@media(max-width:650px){main{padding:18px 12px}.frames{grid-template-columns:repeat(2,1fr)}}@media(max-width:350px){figcaption{font-size:10px}}</style><main><div class="eyebrow">TACTICALGO / 2.5D MOTION DIRECTION</div><h1>三職業 · 四段動作</h1><p>參考《皇室戰爭》的份量感與清楚主道具，保留 TacticalGo 木質桌遊風格。下圖為靜態分鏡示意，時間為設計提案，尚未製作最終角色 pose 或 sprite。</p>'''
for role,title,captions in rows:
    html+='<section class="row"><h2>'+title+'</h2><div class="frames">'
    for phase,caption in enumerate(captions):html+='<figure>'+svg(role,phase)+'<figcaption>'+caption+'</figcaption></figure>'
    html+='</div></section>'
html+='<p class="note">確認後才演出。魔法之手推普通士兵一格、保留歸屬；法師不動。築壘放兩顆普通士兵；盜賊與相鄰敵兵交換。減少動態直接显示終態與文字，命中區不跟裝飾位移。</p><p><a href="https://supercell.com/en/games/clashroyale/">官方視覺參考</a> · 完整說明見 ANIMATION_DIRECTION.md。這些局部棋盤不作正式規則或完整對戰驗收。</p></main></html>'
(ROOT/'ANIMATION_STORYBOARD.html').write_bytes(html.encode('utf-8'))
print('ANIMATION_STORYBOARD.html: three classes, four phases, embedded existing assets')
