/* Deterministic QA only: preserves originals and never retouches artwork. */
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const IDS = ['warrior', 'mage', 'rogue'];
const W = 1320, H = 1030;
function esc(s) { return s.replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }
function label(x,y,s,size=18,color='#433329') { return '<text x="'+x+'" y="'+y+'" fill="'+color+'" font-family="Arial,sans-serif" font-size="'+size+'">'+esc(s)+'</text>'; }
async function measure(file) {
  const bytes = fs.readFileSync(file);
  const meta = await sharp(bytes).metadata();
  const {data,info} = await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let x0=info.width,y0=info.height,x1=-1,y1=-1,zero=0,opaque=0,partial=0;
  for(let y=0;y<info.height;y++) for(let x=0;x<info.width;x++) {
    const a=data[(y*info.width+x)*4+3];
    if(a===0) zero++; else if(a===255) opaque++; else partial++;
    if(a>=13) {x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
  }
  if(x1<0) throw new Error('No visible subject: '+file);
  const bounds=[x0,y0,x1+1,y1+1];
  return {format:meta.format, width:info.width,height:info.height,has_alpha:!!meta.hasAlpha,
    source_color_space:meta.space,icc_profile_present:!!meta.icc,
    file_sha256:sha(bytes),pixel_sha256:sha(data),alpha:{zero,opaque,partial},
    visible_bounds_alpha_gte_13:bounds,
    transparent_and_visible:!!meta.hasAlpha&&zero>0&&(opaque+partial)>0};
}
async function main() {
  const [inputArg,outArg]=process.argv.slice(2);
  if(!inputArg||!outArg) throw new Error('Usage: node review_assets.cjs <originals-dir> <qa-dir>');
  const input=path.resolve(inputArg), out=path.resolve(outArg);
  if(input===out||out.startsWith(input+path.sep)) throw new Error('QA output must be outside originals directory');
  const records=[];
  for(const id of IDS) {
    const file=path.join(input,id+'-v01.png');
    const m=await measure(file);
    if(m.format!=='png'||!m.transparent_and_visible) throw new Error('Requires real transparent PNG: '+file);
    if(m.width!==m.height) throw new Error('Requires a square source canvas: '+file);
    records.push({id,source_filename:path.basename(file),...m});
  }
  if(new Set(records.map(r=>r.width)).size!==1) throw new Error('Different source canvases need a documented shared scale');
  fs.mkdirSync(path.join(out,'previews-1024'),{recursive:true});
  fs.mkdirSync(path.join(out,'sizes'),{recursive:true});
  const overlay=[];
  let bg='<svg width="'+W+'" height="'+H+'" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#eee7db"/>';
  bg+=label(30,38,'TacticalGo | Cozy Tabletop v0.1 | CANDIDATE',26);
  bg+=label(30,69,'Fixed original canvas scale. Native-size samples below. No owner approval / no production anchor.',16);
  for(let i=0;i<records.length;i++) {
    const r=records[i],id=r.id, x=i*440;
    bg+='<rect x="'+(x+20)+'" y="95" width="400" height="440" rx="16" fill="#fffaf1"/>';
    bg+=label(x+40,126,id.toUpperCase(),22);
    bg+=label(x+40,520,id==='warrior'?'Broad shield / short sword':id==='mage'?'Pointed hat / crystal staff':'Rounded hood / short dagger',17);
    const source=path.join(input,r.source_filename);
    const scaled=await sharp(source).resize(896,896,{kernel:'lanczos3'}).png().toBuffer();
    const normalized=await sharp({create:{width:1024,height:1024,channels:4,background:{r:0,g:0,b:0,alpha:0}}})
      .composite([{input:scaled,left:64,top:64}]).png().toBuffer();
    const normPath=path.join(out,'previews-1024',id+'-preview-1024.png');
    fs.writeFileSync(normPath,normalized);
    r.preview_1024=await measure(normPath);
    r.preview_transform={source_canvas_scale:896/r.width,translation:[64,64],kernel:'lanczos3',
      color_policy:'sharp default decode; untagged output; no certified sRGB claim',semantic_ground_anchor:null,
      anchor_status:'not_measured',production_delivery:false};
    overlay.push({input:await sharp(normalized).resize(350,350).png().toBuffer(),left:x+45,top:145});
    bg+=label(x+22,576,'px',15);
    bg+=label(x+72,576,'Light',15);
    bg+=label(x+164,576,'Dark',15);
    bg+=label(x+252,576,'Gray',15);
    bg+=label(x+333,576,'Shape',15);
    let row=0;
    for(const size of [32,48,64]) {
      const yy=602+row*111;
      bg+=label(x+22,yy+43,String(size),18);
      const sprite=await sharp(normalized).resize(size,size,{kernel:'lanczos3'}).png().toBuffer();
      fs.writeFileSync(path.join(out,'sizes',id+'-'+size+'.png'),sprite);
      const gray=await sharp(sprite).greyscale().png().toBuffer();
      const {data,info}=await sharp(sprite).ensureAlpha().raw().toBuffer({resolveWithObject:true});
      for(let p=0;p<data.length;p+=4) {data[p]=33;data[p+1]=27;data[p+2]=23;}
      const silhouette=await sharp(data,{raw:info}).png().toBuffer();
      for(let col=0;col<4;col++) {
        const xx=x+57+col*88;
        bg+='<rect x="'+xx+'" y="'+yy+'" width="78" height="82" rx="8" fill="'+(col===1?'#282a32':'#fffaf1')+'"/>';
        overlay.push({input:col===2?gray:col===3?silhouette:sprite,left:xx+Math.floor((78-size)/2),top:yy+Math.floor((82-size)/2)});
      }
      row++;
    }
  }
  bg+=label(30,993,'Color, grayscale and silhouette are review evidence, not player recognition test results.',17);
  bg+='</svg>';
  await sharp(Buffer.from(bg)).composite(overlay).png().toFile(path.join(out,'contact-sheet.png'));
  // Deterministic faction/overlay experiment: QA graphic, not application UI.
  const BW=840,BH=450, comps=[];
  let board='<svg width="'+BW+'" height="'+BH+'" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#eee7db"/>';
  board+=label(22,30,'Team shapes and external hints | 64px candidate units',22);
  for(let row=0;row<2;row++) for(let col=0;col<3;col++) {
    const cx=140+col*280,cy=133+row*190;
    board+='<rect x="'+(cx-82)+'" y="'+(cy-76)+'" width="164" height="152" fill="#d8ba8e" rx="10"/>';
    for(let t=-1;t<=1;t++) {
      board+='<path d="M '+(cx-75)+' '+(cy+t*48)+' H '+(cx+75)+' M '+(cx+t*48)+' '+(cy-70)+' V '+(cy+70)+'" stroke="#ad895d" stroke-width="1"/>';
    }
    // Hints occupy neighboring intersections and do not sit behind the unit.
    board+='<circle cx="'+(cx+55)+'" cy="'+(cy-50)+'" r="10" fill="none" stroke="#327765" stroke-width="3"/>';
    board+='<path d="M '+(cx-61)+' '+(cy-62)+' l 12 22 h -24 Z" fill="#edb443" stroke="#433329" stroke-width="2"/>';
    if(row===0) board+='<circle cx="'+cx+'" cy="'+(cy+28)+'" r="38" fill="#fff8e4" stroke="#342b26" stroke-width="3"/><circle cx="'+cx+'" cy="'+(cy+67)+'" r="5" fill="#fff8e4" stroke="#342b26" stroke-width="2"/>';
    else {
      board+='<polygon points="'+[[-40,0],[-20,-35],[20,-35],[40,0],[20,35],[-20,35]].map(([a,b])=>(cx+a)+','+(cy+28+b)).join(' ')+'" fill="#292c35" stroke="#fff8e4" stroke-width="3"/>';
      board+='<path d="M '+cx+' '+(cy+65)+' l 7 12 h -14 Z" fill="#fff8e4"/>';
    }
    comps.push({input:fs.readFileSync(path.join(out,'sizes',IDS[col]+'-64.png')),left:cx-32,top:cy-36});
    board+=label(cx-96,cy+96,(row===0?'Ivory circle + dot':'Dark hex + triangle')+' / '+IDS[col],13);
  }
  board+='</svg>';
  await sharp(Buffer.from(board)).composite(comps).png().toFile(path.join(out,'faction-overlay-64.png'));
  const evidence={schema_version:1,tool:'sharp',tool_version:sharp.versions,
    alpha_gate_passed:records.every(r=>r.transparent_and_visible),
    artwork_retouched:false,sample_sizes:[32,48,64],records,
    claim_boundary:{owner_approval:'pending',rights:'pending',production_available:false,
      player_recognition_test:'not_run',consumer_ui_test:'not_run',kck_delivery_anchor:'not_measured'}};
  fs.writeFileSync(path.join(out,'validation.json'),JSON.stringify(evidence,null,2)+'\n');
  console.log(JSON.stringify({alpha_gate_passed:evidence.alpha_gate_passed,characters:records.map(r=>({id:r.id,source:[r.width,r.height],preview:[r.preview_1024.width,r.preview_1024.height],sha256:r.file_sha256})),out},null,2));
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
