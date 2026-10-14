/* Browser presentation study only. Swift receipt validation and playback are separate. */
(function(global){
 const clamp=x=>Math.max(0,Math.min(1,x)),ease=x=>{x=clamp(x);return x*x*(3-2*x)},lerp=(a,b,t)=>[a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t];
 function progress(t,p){return ease((t-p.moveStart)/(p.arrival-p.moveStart))}
 function arc(a,b,t,pitch){const dx=b[0]-a[0],dy=b[1]-a[1],d=Math.hypot(dx,dy);if(!d||t<=0||t>=1||!Number.isFinite(t))return [0,0];const h=Math.sin(Math.PI*t)*pitch*.32;return [-dy/d*h,dx/d*h]}
 function transfer(move,p,t,pitch,candidate=true){const u=progress(t,p);let a=move.from,b=move.to,v=u;if(p.kind==='chain'){if(move.kind==='hero'){a=u<.5?a:p.middle;b=u<.5?p.middle:b;v=u<.5?u*2:(u-.5)*2}else if(candidate){v=move.first?Math.min(1,u*2):Math.max(0,(u-.5)*2)}}const q=lerp(a,b,v);if(candidate&&(p.kind==='swap'||p.kind==='chain')){const o=arc(a,b,v,pitch);return [q[0]+o[0],q[1]+o[1]]}return q}
 function squash(t){if(t<.4||t>=1.08)return 1;if(t<.46)return 1-.16*clamp((t-.4)/.06);if(t<.68)return .84+.16*clamp((t-.46)/.12);if(t<.73)return .84;const u=clamp((t-.73)/.15);return u<.55?.84+.24*u/.55:1.08-.08*(u-.55)/.45}
 function token(p,t,moving=false,move=null){const f={x:1,y:1,lift:0,tilt:0,opacity:1};if(!Number.isFinite(t)||t<0||t>=p.duration)return f;const land=clamp((t-p.arrival)/.18),pulse=t>=p.arrival?Math.sin(Math.PI*land)*(1-land):0;if(p.hero==='mage'){f.y=squash(t);f.x=2-f.y}else if(p.hero==='warrior'){const hit=t>=p.arrival?1-ease((t-p.arrival-.04)/.14):0;f.x=1+.14*hit;f.y=1-.16*hit;if(moving)f.lift=-.16*Math.sin(Math.PI*progress(t,p))}else if(p.hero==='rogue'&&moving){let v=progress(t,p);if(p.kind==='chain'&&move)v=move.kind==='hero'?(v<.5?v*2:(v-.5)*2):move.first?Math.min(1,v*2):Math.max(0,(v-.5)*2);const u=Math.sin(Math.PI*v);f.x=1+.06*u;f.y=1-.05*u;f.tilt=-7*u}return f}
 function offering(t,p){if(!Number.isFinite(t)||t<p.release||t>=p.arrival+.24)return {opacity:0,lift:0,spread:0};const u=(t-p.release)/(p.arrival-p.release+.24);return {opacity:Math.sin(Math.PI*u)*.9,lift:u*.55,spread:Math.sin(Math.PI*u)*.16}}
 function donor(t,p){const u=clamp((t-p.release)/(p.arrival-p.release));return {opacity:1-u,lift:-.18*u,x:1-.18*u,y:1+.10*u,tilt:0}}
 global.AV21={clamp,ease,lerp,progress,arc,transfer,token,offering,donor};
})(typeof window==='undefined'?globalThis:window);
