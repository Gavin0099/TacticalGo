/* Original painted sprites, sampled without changing source pixels. */
function paintEnhancedAccents(c,image,f,t,pitch,xy,layer='ground'){
 if(!Number.isFinite(t)||t<0||t>=f.duration)return;
 const charge=t<f.release?AV21.ease(t/Math.max(.001,f.release))*.65:Math.max(0,1-(t-f.release)/.10)*.65;
 const u=AV21.clamp((t-f.arrival)/.22),impact=t>=f.arrival&&t<f.arrival+.22?(1-u)**2:0,scale=.86+.34*u;
 function sprite(index,q,size,alpha,angle=0){if(alpha<=0)return;c.save();c.translate(...q);c.rotate(angle);c.globalAlpha=alpha;const edge=image.width/4;c.drawImage(image,(index%4)*edge,Math.floor(index/4)*image.height/2,edge,image.height/2,-size/2,-size/2,size,size);c.restore()}
 if(layer==='ground'&&f.hero==='warrior'){sprite(5,xy(f.origin),pitch*.88,charge*.32);for(const target of [...f.placements,...f.transfers.map(m=>m.to)]){sprite(0,xy(target),pitch*1.44*scale,impact*.82);sprite(5,xy(target),pitch*1.26*scale,impact*.46)}}
 if(f.hero==='mage'){const q=xy(f.origin),tip=ArtworkRig.tip(pitch*.92,t,f,true);if(layer==='foreground')sprite(4,[q[0]+tip[0],q[1]+tip[1]],pitch*.66,charge);if(layer==='ground')for(const m of f.transfers)sprite(1,xy(m.to),pitch*1.30*scale,impact*.76)}
 if(layer==='ground'&&f.hero==='rogue'){for(const move of f.transfers){const m={...move,from:xy(move.from),to:xy(move.to)},p={...f,middle:f.middle?xy(f.middle):null},u=AV21.progress(t,f),stage=move.kind==='hero'?u:f.kind==='chain'?(move.first?Math.min(1,u*2):Math.max(0,(u-.5)*2)):u;const q=AV21.transfer(m,p,t,pitch,true),alpha=t>=f.moveStart&&t<f.arrival?Math.sin(Math.PI*stage)*.64:0;sprite(move.kind==='hero'?2:6,q,pitch*1.06,alpha,Math.atan2(m.to[1]-m.from[1],m.to[0]-m.from[0]))}}
 if(f.hero==='priest'&&f.sacrifice){const q=xy(f.sacrifice),leaf=AV21.offering(t,f);if(layer==='foreground')sprite(3,[q[0],q[1]-pitch*leaf.lift],pitch*1.10,leaf.opacity*.80);else sprite(7,q,pitch*1.26*scale,impact*.64)}
}
