'use strict';
// QA derivatives only; source artwork remains byte-for-byte unchanged.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const root = __dirname;
const qa = path.join(root, 'qa');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const sources = [
  { id:'warrior-reference', label:'Warrior / current portrait', role:'composition and rendering reference', file:'/Users/pc49-58/TacticalGo-safety/wt-shell-copy/ios/TacticalGo/Assets.xcassets/warrior.imageset/portrait.png' },
  { id:'priest-current-crop', label:'Priest / current crop', role:'comparison only, not generation input', file:'/Users/pc49-58/TacticalGo-safety/wt-shell-copy/ios/TacticalGo/Assets.xcassets/priest-portrait-bust-v01.imageset/priest-portrait-bust-v01.png' },
  { id:'priest-redraw-v01', label:'Priest / new portrait candidate', role:'generated output', file:path.join(root,'priest-portrait-redraw-v01.png') }
];
async function measure(file) {
  const bytes = fs.readFileSync(file);
  const {data,info} = await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let zero=0, partial=0, opaque=0, x0=info.width, y0=info.height, x1=-1, y1=-1;
  for(let y=0;y<info.height;y++) for(let x=0;x<info.width;x++) {
    const a=data[(y*info.width+x)*4+3];
    if(a===0) zero++; else if(a===255) opaque++; else partial++;
    if(a>=13) {x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
  }
  return {width:info.width,height:info.height,file_sha256:sha(bytes),decoded_rgba_sha256:sha(data),alpha:{zero,partial,opaque},visible_bounds_alpha_gte_13:[x0,y0,x1+1,y1+1],true_transparency:zero>0&&opaque+partial>0};
}
async function main() {
  fs.mkdirSync(qa,{recursive:true});
  const records=[]; const layers=[]; const backgrounds=['#fff8e9','#252a32','#fff8e9','#fff8e9'];
  let svg='<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="760"><rect width="100%" height="100%" fill="#e9e1d4"/><g font-family="Arial" fill="#352b24"><text x="24" y="32" font-size="23">TacticalGo priest portrait / scale review</text><text x="24" y="57" font-size="14">Same square-canvas scale; native-size samples; candidate art, not in-game validation.</text>';
  for(let i=0;i<sources.length;i++) {
    const source=sources[i]; const x=i*360;
    records.push({...source,...await measure(source.file)});
    svg+='<rect x="'+(x+16)+'" y="76" width="328" height="310" rx="12" fill="#fff8e9"/><text x="'+(x+26)+'" y="101" font-size="17">'+source.label+'</text>';
    layers.push({input:await sharp(source.file).resize(260,260,{fit:'contain',background:'#00000000'}).png().toBuffer(),left:x+50,top:112});
    ['Light','Dark','Gray','Shape'].forEach((label,c)=>{svg+='<text x="'+(x+38+c*78)+'" y="416" font-size="13">'+label+'</text>';});
    for(let r=0;r<3;r++) {
      const size=[32,48,64][r]; const y=432+r*92;
      const sprite=await sharp(source.file).resize(size,size,{fit:'contain',background:'#00000000'}).png().toBuffer();
      if(i===2) fs.writeFileSync(path.join(qa,'priest-redraw-'+size+'px.png'),sprite);
      const gray=await sharp(sprite).greyscale().toColourspace('srgb').png().toBuffer();
      const raw=await sharp(sprite).ensureAlpha().raw().toBuffer({resolveWithObject:true});
      for(let p=0;p<raw.data.length;p+=4) {raw.data[p]=41;raw.data[p+1]=32;raw.data[p+2]=26;}
      const shape=await sharp(raw.data,{raw:raw.info}).png().toBuffer();
      svg+='<text x="'+(x+3)+'" y="'+(y+41)+'" font-size="11">'+size+'</text>';
      for(let c=0;c<4;c++) {
        const left=x+30+c*78;
        svg+='<rect x="'+left+'" y="'+y+'" width="72" height="80" rx="5" fill="'+backgrounds[c]+'"/>';
        layers.push({input:c===2?gray:c===3?shape:sprite,left:left+Math.floor((72-size)/2),top:y+Math.floor((80-size)/2)});
      }
    }
  }
  svg+='<text x="24" y="746" font-size="13">32 px loses face and finger detail. Full portrait review does not certify a finished board token.</text></g></svg>';
  await sharp(Buffer.from(svg)).composite(layers).png().toFile(path.join(qa,'scale-review.png'));
  const identity='/Users/pc49-58/TacticalGo-safety/wt-shell-copy/assets/candidates/priest-08/v02/priest-v02.png';
  const style='/Users/pc49-58/Desktop/TacticalGo/.agents/skills/tacticalgo-character-style/assets/warrior-v01.png';
  const result={created_local_date:'2026-10-17',generator:'built-in image_gen',model:'unknown',tool_version:'unknown',transparent_background_requested:true,original_preserved:true,prompt:'PROMPT.txt',generation_inputs:[{role:'priest identity',file:identity,...await measure(identity)},records[0]],fixed_style_reference:{file:style,manifest_sha256:'49fe18591e9e64836130ee09ef6b173f5cb3e32f78962cb6a015b877f58fb322',...await measure(style)},records,qa:{sample_sizes:[32,48,64],light_dark_grayscale_silhouette:true,derivative_tool:'sharp',derivative_tool_version:sharp.versions.sharp,owner_visual_approval:'pending',consumer_ui:'not_run',board_token:'not_authored'},approval:'pending_exact_file_owner_review',availability:{candidate:true,production:false,animation:false},rights:'pending'};
  fs.writeFileSync(path.join(root,'PROVENANCE.json'),JSON.stringify(result,null,2)+'\n');
  const output=records[2];
  if(!output.true_transparency) throw new Error('Output lacks visible subject or genuine transparency');
  if(result.fixed_style_reference.file_sha256!==result.fixed_style_reference.manifest_sha256) throw new Error('Fixed style-reference hash mismatch');
  console.log(JSON.stringify({output,reference_hash_match:true,review:path.join(qa,'scale-review.png')},null,2));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
