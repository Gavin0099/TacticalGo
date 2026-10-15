// Deterministic review derivatives only; the two original PNGs are never edited.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const root = __dirname, out = path.join(root, 'qa');
const assets = ['slime-user-original', 'slime-token-v02', 'shadow-wolf-preview-v02'];
const label = (x,y,t,size=16) => `<text x="${x}" y="${y}" fill="#433329" font-family="Arial" font-size="${size}">${t}</text>`;
(async () => {
 fs.mkdirSync(path.join(out,'sizes'),{recursive:true});
 const records=[], overlays=[];
 let svg='<svg xmlns="http://www.w3.org/2000/svg" width="1370" height="870"><rect width="1370" height="870" fill="#eee7db"/>';
 svg+=label(24,32,'TacticalGo monster v02 preview | CANDIDATE | user original / simplified slime / user wolf',21);
 for(let i=0;i<assets.length;i++) {
  const id=assets[i], file=path.join(root,id+'.png'), bytes=fs.readFileSync(file), m=await sharp(bytes).metadata();
  const {data,info}=await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let zero=0,opaque=0,partial=0,x0=info.width,y0=info.height,x1=-1,y1=-1;
  for(let y=0;y<info.height;y++) for(let x=0;x<info.width;x++) {
   const a=data[(y*info.width+x)*4+3];
   if(a===0) zero++; else if(a===255) opaque++; else partial++;
   if(a>=13) { x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y); }
  }
  const alphaPass=!!m.hasAlpha && zero>0 && opaque>0 && x0>0 && y0>0 && x1<info.width-1 && y1<info.height-1;
  if(m.format!=='png'||info.width!==info.height||!alphaPass) throw Error('Transparency, clipping or format gate failed: '+id);
  const x=i*450+10;
  svg+=`<rect x="${x}" y="55" width="430" height="355" rx="14" fill="#fffaf1"/>`;
  svg+=label(x+16,84,id,20);
  overlays.push({input:await sharp(bytes).resize(286,286).png().toBuffer(),left:x+72,top:100});
  ['Light','Dark','Gray','Silhouette'].forEach((t,col)=>{ svg+=label(x+66+col*91,442,t,14); });
  for(const [row,size] of [32,48,64].entries()) {
   const y=460+row*112;
   svg+=label(x+8,y+45,String(size));
   const sample=await sharp(bytes).resize(size,size,{kernel:'lanczos3'}).png().toBuffer();
   fs.writeFileSync(path.join(out,'sizes',id+'-'+size+'.png'),sample);
   const gray=await sharp(sample).greyscale().png().toBuffer();
   const shape=await sharp(sample).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   for(let p=0;p<shape.data.length;p+=4) {shape.data[p]=33;shape.data[p+1]=27;shape.data[p+2]=23;}
   const silhouette=await sharp(shape.data,{raw:shape.info}).png().toBuffer();
   for(let col=0;col<4;col++) {
    const xx=x+47+col*91;
    svg+=`<rect x="${xx}" y="${y}" width="82" height="84" rx="6" fill="${col===1?'#282a32':'#fffaf1'}"/>`;
    overlays.push({input:col===2?gray:col===3?silhouette:sample,left:xx+Math.floor((82-size)/2),top:y+Math.floor((84-size)/2)});
   }
  }
  records.push({id,filename:id+'.png',width:info.width,height:info.height,has_alpha:m.hasAlpha,file_sha256:sha(bytes),decoded_rgba_sha256:sha(data),alpha:{zero,opaque,partial},visible_bounds_alpha_gte_13:[x0,y0,x1+1,y1+1],alpha_gate_passed:alphaPass});
 }
 svg+=label(24,839,'Native 32 / 48 / 64px; paper grain and face details diminish at 32px. No player recognition claim.');
 svg+='</svg>';
 await sharp(Buffer.from(svg)).composite(overlays).png().toFile(path.join(out,'scale-review.png'));
 fs.writeFileSync(path.join(out,'validation.json'),JSON.stringify({schema:'monster-art-qa-v1',tool:'sharp',tool_versions:sharp.versions,alpha_gate_passed:true,qa_derivatives_retouch_originals:false,sizes:[32,48,64],records},null,2)+'\n');
 console.log(JSON.stringify({alpha_gate_passed:true,records},null,2));
})().catch(e=>{console.error(e.message);process.exitCode=1});
