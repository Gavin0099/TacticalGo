/* Contact geometry study mirrors the authored native ground layer; no receipt validation here. */
const ContactStudy=(()=>{
 let cfg=null;
 const beats=f=>{
  if(f.kind==='chain')return [{at:f.origin,from:f.middle,start:(f.moveStart+f.arrival)/2},{at:f.middle,from:f.origin,start:(f.moveStart+f.arrival)/2},{at:f.middle,from:f.transfers[0].to,start:f.arrival},{at:f.transfers[0].to,from:f.middle,start:f.arrival}];
  if(f.sacrifice)return [{at:f.sacrifice,from:null,start:f.arrival}];
  const seen=new Set();return [...f.placements,...f.transfers.map(m=>m.to)].filter(q=>{const k=q.join(',');if(seen.has(k))return false;seen.add(k);return true}).map(q=>({at:q,from:f.transfers.find(m=>m.to.join(',')===q.join(','))?.from||f.origin,start:f.arrival}));
 };
 function frame(t,start,end,reduced=false){const quiet={opacity:0,radius:cfg.radius,rise:0};if(reduced||![t,start,end].every(Number.isFinite)||start<0||end<=start||t<start||t>=end||t>=start+cfg.tail)return quiet;const u=AV21.clamp((t-start)/cfg.tail);return {opacity:1-AV21.ease((u-cfg.holdFraction)/cfg.fadeFraction),radius:cfg.radius+cfg.radiusDelta*AV21.ease(u),rise:cfg.rise*u}}
 function paint(c,f,t,pitch,xy){for(const beat of beats(f)){const p=frame(t,beat.start,f.duration);if(!p.opacity)continue;const q=xy(beat.at),r=pitch*p.radius;c.save();c.translate(q[0],q[1]+pitch*.05);c.beginPath();c.rect(-pitch*.49,-pitch*.54,pitch*.98,pitch*.98);c.clip();c.globalAlpha=p.opacity;
  function ellipse(rx,ry,color,width=0){c.beginPath();c.ellipse(0,0,rx,ry,0,0,Math.PI*2);if(width){c.strokeStyle=color;c.lineWidth=width;c.stroke()}else{c.fillStyle=color;c.fill()}}
  ellipse(r,r*.34,'#243f4361');
  if(f.hero==='warrior'){for(const sign of [-1,1]){c.beginPath();c.moveTo(r*.42*sign,-r*.23);c.lineTo(r*sign,-r*.07);c.lineTo(r*.85*sign,r*.25);c.lineTo(r*.38*sign,r*.30);c.closePath();c.fillStyle='#d9b46cd9';c.fill();c.strokeStyle='#243f43b8';c.lineWidth=Math.max(1,pitch*.035);c.stroke()}}
  if(f.hero==='mage'){ellipse(r,r*.34,'#59446fcc',Math.max(2,pitch*.10));ellipse(r,r*.34,'#98ff98d9',Math.max(1,pitch*.035));for(const sign of [-1,1]){c.beginPath();c.moveTo(r*.72*sign,-r*.25);c.lineTo(r*.90*sign,-r*.42);c.lineWidth=Math.max(1,pitch*.05);c.lineCap='round';c.strokeStyle='#f4ead8';c.stroke()}}
  if(f.hero==='rogue'){const source=beat.from?xy(beat.from):q;c.rotate(Math.atan2(q[1]-source[1],q[0]-source[0]));for(const [color,width]of [['#243f43e6',Math.max(3,pitch*.14)],['#6c9276',Math.max(2,pitch*.08)],['#f4ead8e6',Math.max(1,pitch*.025)]]){c.beginPath();c.moveTo(-r,r*.20);c.quadraticCurveTo(r*.12,-r*.38,r,-r*.20);c.strokeStyle=color;c.lineWidth=width;c.lineCap='round';c.stroke()}}
  if(f.hero==='priest'){ellipse(r*.86,r*.28,'#d9b46cd9',Math.max(1,pitch*.06));for(const sign of [-1,1]){const x=r*.65*sign,lift=pitch*p.rise;c.beginPath();c.moveTo(x,-lift);c.quadraticCurveTo(x-r*.15*sign,-lift-r*.38,x+r*.10*sign,-lift-r*.58);c.strokeStyle='#d9b46c';c.lineWidth=Math.max(1,pitch*.055);c.lineCap='round';c.stroke()}}
  c.restore();}}
 return {init:data=>cfg=data,beats,frame,paint};
})();
