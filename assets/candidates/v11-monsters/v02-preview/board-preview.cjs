// Static presentation only. Real PNGs are composited without modifying originals.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const root = __dirname;
const text = (x,y,t,s=16,c='#433329') => `<text x="${x}" y="${y}" font-family="Arial" font-size="${s}" fill="${c}">${t}</text>`;
(async () => {
 const overlays=[];
 let svg='<svg xmlns="http://www.w3.org/2000/svg" width="920" height="660"><rect width="920" height="660" fill="#eee7db"/>';
 svg+=text(24,34,'TacticalGo | Monster art v02',25);
 svg+=text(24,60,'Simplified slime + user-provided wolf / static 9 x 9 visual mockup');
 for(let panel=0;panel<2;panel++) {
  const left=20+460*panel, dark=panel===1, ox=left+57, oy=139, gap=38;
  svg+=`<rect x="${left}" y="78" width="420" height="426" rx="16" fill="${dark?'#282a32':'#ead2ad'}"/>`;
  svg+=text(left+20,107,dark?'Dark contrast study':'Light board / 32 px art',18,dark?'#fff0d4':'#4f3727');
  for(let i=0;i<9;i++) {
   svg+=`<path d="M ${ox+i*gap} ${oy} v ${8*gap} M ${ox} ${oy+i*gap} h ${8*gap}" stroke="${dark?'#7b807d':'#8f7052'}" stroke-width="1"/>`;
   svg+=text(ox+i*gap-5,oy+8*gap+28,'ABCDEFGHI'[i],13,dark?'#d3d4ce':'#68513f');
   svg+=text(ox-25,oy+i*gap+5,String(9-i),13,dark?'#d3d4ce':'#68513f');
  }
  // Illustrative positions; deliberately no claim of a legal engine replay.
  for(const [x,y,black] of [[1,4,true],[3,4,true],[1,3,false],[2,5,false],[5,4,true],[7,4,true],[6,3,false],[6,5,false],[0,0,false],[4,6,true],[4,2,false]]) {
   svg+=`<circle cx="${ox+x*gap}" cy="${oy+y*gap}" r="12" fill="${black?'#332b27':'#fff9ed'}" stroke="${black?'#160f0c':'#a89983'}" stroke-width="1.5"/>`;
  }
  for(const [id,x,y] of [['slime-token-v02',2,4],['shadow-wolf-preview-v02',6,4]]) {
   svg+=`<circle cx="${ox+x*gap}" cy="${oy+y*gap}" r="17" fill="#fff6de" stroke="#3f765b" stroke-width="1.5"/>`;
   overlays.push({input:await sharp(path.join(root,id+'.png')).resize(32,32).png().toBuffer(),left:ox+x*gap-16,top:oy+y*gap-16});
  }
 }
 svg+=text(24,541,'64 px detail',18);
 for(const [i,id] of ['slime-token-v02','shadow-wolf-preview-v02'].entries()) {
  const x=180+i*325;
  svg+=`<rect x="${x}" y="520" width="80" height="80" rx="12" fill="#fffaf1"/>`;
  overlays.push({input:await sharp(path.join(root,id+'.png')).resize(64,64).png().toBuffer(),left:x+8,top:528});
  svg+=text(x+95,550,i?'Shadow wolf':'Sticky slime',18);
  svg+=text(x+95,577,i?'Original retained':'Droplets removed',14);
 }
 svg+=text(24,635,'Candidate preview. External neutral rings. No app integration or player recognition claim.',14);
 svg+='</svg>';
 fs.writeFileSync(path.join(root,'qa/board-preview.svg'),svg);
 await sharp(Buffer.from(svg)).composite(overlays).png().toFile(path.join(root,'qa/board-preview.png'));
 console.log('board-preview.png written; native 32 px art, 38 px grid; 64 px detail.');
})().catch(e=>{console.error(e);process.exitCode=1;});
