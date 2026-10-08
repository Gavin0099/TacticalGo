/* Focused observable checks for this review tool; not gameplay or human tests. */
const fs=require('fs'),path=require('path'),assert=require('node:assert/strict');
const {pathToFileURL}=require('url');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..'),out=path.join(root,'qa');
const results=[],screenshots=[],errors=[],desktopMeasurements=[];
async function check(name,fn){await fn();results.push({name,status:'pass'});}
async function main(){
 const executable=process.env.VIS_FEEL_CHROME;if(!executable)throw new Error('Set VIS_FEEL_CHROME to an available Chromium/Chrome executable');
 const browser=await chromium.launch({executablePath:executable,headless:true});
 const page=await browser.newPage({viewport:{width:1050,height:1150}});
 page.on('pageerror',e=>errors.push(e.message));
 const requests=[];page.on('request',r=>requests.push(r.url()));
 await page.goto(pathToFileURL(path.join(root,'REVIEW.html')).href);
 const snap=()=>page.evaluate(()=>window.VIS_FEEL.snapshot());
 const action=()=>page.locator('.panel[data-mode=motion] [data-action=primary]').click();
 const scene=s=>page.locator('[data-scene='+s+']').click();
 const reset=()=>page.locator('#reset').click();
 async function equalPanels(){const boards=await page.locator('.board').evaluateAll(bs=>bs.map(b=>b.dataset.fixture));assert.equal(boards[0],boards[1]);}
 async function screen(name){await page.screenshot({path:path.join(out,name),fullPage:true});screenshots.push(name);}
 await check('offline boot: all six assets embedded; no HTTP dependency',async()=>{
  await page.locator('.token-art').first().waitFor();assert.equal(await page.evaluate(()=>Object.keys(window.FEEL_ASSETS).length),6);
  assert.equal(await page.locator('img').evaluateAll(xs=>xs.every(x=>x.complete&&x.naturalWidth===512)),true);
  assert.equal(requests.some(u=>/^https?:/.test(u)),false);await equalPanels();
 });
 for(const profile of ['7-390','9-320']){
  await page.locator('#profile').selectOption(profile);desktopMeasurements.push(await page.locator('.panel[data-mode=static]').evaluate(el=>({n:window.VIS_FEEL.snapshot().n,frame:el.querySelector('.phone').getBoundingClientRect().width,pitch:Number(el.querySelector('.board').dataset.pitch),token:el.querySelector('.token-art').getBoundingClientRect().width})));
  for(const role of ['warrior','mage','rogue']){
   await scene('select');await page.locator('#role').selectOption(role);
   await check(profile+' selection '+role+': same state, stable hit area, bounded motion',async()=>{
    const boxInBoard=()=>page.locator('.panel[data-mode=motion] .point[data-kind=hero][data-team=light]').evaluate(el=>{const p=el.getBoundingClientRect(),b=el.closest('.board').getBoundingClientRect();return {width:p.width,height:p.height,x:p.x-b.x,y:p.y-b.y};});const before=await boxInBoard();
    await page.evaluate(()=>document.querySelector('.panel[data-mode=motion] [data-action=primary]').click());assert.equal((await snap()).selected,true);assert.equal((await snap()).ap,2);await equalPanels();
    const after=await boxInBoard();assert.deepEqual(after,before);
    assert.equal(await page.locator('.marker.selection').count(),2);await page.waitForFunction(()=>document.getAnimations().every(a=>a.playState!=='running'),null,{timeout:1500});
    assert.equal(await page.evaluate(()=>document.getAnimations().filter(a=>a.playState==='running').length),0);
   });
  }
  await screen('SELECT_'+profile+'.png');
  await scene('skill');
  await check(profile+' magic-hand preview and cancellation preserve all pieces and resources',async()=>{
   const initial=await snap();await action();const preview=await snap();assert.equal(preview.phase,'preview');assert.deepEqual(preview.units,initial.units);assert.equal(preview.ap,2);assert.equal(preview.mana,3);
   await page.locator('.panel[data-mode=motion] [data-action=cancel]').click();const canceled=await snap();assert.equal(canceled.phase,'idle');assert.deepEqual(canceled.units,initial.units);assert.equal(canceled.ap,2);assert.equal(canceled.mana,3);
  });
  await action();await screen('PUSH_PREVIEW_'+profile+'.png');
  await check(profile+' magic-hand confirmation: one orthogonal move; same faction; caster and commanders stable',async()=>{
   const before=await snap();await page.evaluate(()=>document.querySelector('.panel[data-mode=motion] [data-action=primary]').click());assert.equal(await page.evaluate(()=>document.getAnimations().length>0),true);const after=await snap(),from=before.targets.push,to=before.targets.destination;
   assert.equal(after.ap,1);assert.equal(after.mana,1);assert.equal(after.captured,0);assert.equal(after.units.length,before.units.length);
   assert.equal(after.units.some(u=>u.x===from.x&&u.y===from.y),false);
   assert.equal(after.units.find(u=>u.x===to.x&&u.y===to.y).team,'dark');
   assert.deepEqual(after.units.filter(u=>u.kind!=='soldier'),before.units.filter(u=>u.kind!=='soldier'));await equalPanels();
   await page.waitForTimeout(250);assert.equal(await page.locator('.marker.danger').count(),2);assert.equal(await page.locator('.route').count(),2);
  });
  await screen('PUSH_RESULT_'+profile+'.png');
  await scene('capture');
  await check(profile+' capture fixture and preview: black stone has exactly the marked final empty neighbor',async()=>{
   const s=await snap(),p=s.targets.capture;const neighbors=[[p.x-1,p.y],[p.x+1,p.y],[p.x,p.y-1],[p.x,p.y+1]].map(([x,y])=>s.units.find(u=>u.x===x&&u.y===y));assert.equal(neighbors.filter(u=>u?.team==='light').length,3);assert.equal(neighbors.filter(u=>!u).length,1);
   await action();assert.deepEqual((await snap()).units,s.units);assert.equal((await snap()).ap,2);
  });
  await check(profile+' capture result: final white placement, black stone removal, effects below information',async()=>{
   const before=await snap();await action();const after=await snap();assert.equal(after.ap,1);assert.equal(after.mana,3);assert.equal(after.captured,1);assert.equal(after.units.find(u=>u.x===after.targets.drop.x&&u.y===after.targets.drop.y).team,'light');assert.equal(after.units.some(u=>u.x===after.targets.capture.x&&u.y===after.targets.capture.y),false);assert.deepEqual(after.units.filter(u=>u.kind!=='soldier'),before.units.filter(u=>u.kind!=='soldier'));await equalPanels();
   const layers=await page.evaluate(()=>({effect:Number(getComputedStyle(document.querySelector('.effect')).zIndex),danger:Number(getComputedStyle(document.querySelector('.marker.danger')).zIndex),liberty:Number(getComputedStyle(document.querySelector('.marker.liberty')).zIndex),pointer:getComputedStyle(document.querySelector('.effect')).pointerEvents}));assert(layers.effect<layers.danger&&layers.effect<layers.liberty);assert.equal(layers.pointer,'none');await page.waitForTimeout(210);assert.equal(await page.locator('.effect').count(),0);
  });
  await screen('CAPTURE_RESULT_'+profile+'.png');
 }
 await check('reset during active motion leaves no stale effects or resource deductions',async()=>{
  await scene('skill');await action();await action();await reset();await page.waitForTimeout(300);assert.equal((await snap()).phase,'idle');assert.equal((await snap()).ap,2);assert.equal((await snap()).mana,3);assert.equal(await page.locator('.effect').count(),0);assert.equal(await page.evaluate(()=>document.getAnimations().filter(a=>a.playState==='running').length),0);
 });
 await check('manual reduced motion: confirmed results immediate, no animation required',async()=>{
  await page.locator('#reduce').check();await action();await action();assert.equal((await snap()).phase,'done');assert.equal((await snap()).reduced,true);assert.equal(await page.evaluate(()=>document.getAnimations().length),0);await screen('REDUCED_MOTION_9-320.png');
 });
 await page.locator('#reduce').uncheck();await page.emulateMedia({reducedMotion:'reduce'});
 await check('system reduced motion wins even with manual checkbox off',async()=>{
  await scene('select');await action();assert.equal((await snap()).reduced,true);assert.equal(await page.evaluate(()=>document.getAnimations().length),0);
 });
 await page.emulateMedia({reducedMotion:'no-preference'});
 await check('keyboard selection button action works',async()=>{
  await reset();const hero=page.locator('.panel[data-mode=motion] .point[data-kind=hero][data-team=light]');await hero.focus();await page.keyboard.press('Enter');assert.equal((await snap()).selected,true);
 });
 await page.locator('#gray').check();await screen('GRAYSCALE_9-320.png');await page.locator('#gray').uncheck();
 const measurements=[];
 for(const [n,width] of [[7,390],[9,320]]){
  await page.setViewportSize({width,height:1150});await page.locator('#profile').selectOption(n+'-'+width);await scene('select');await page.locator('#role').selectOption('mage');await action();await page.waitForTimeout(210);
  await check('mobile viewport '+width+': no horizontal overflow; protected marker hit testing',async()=>{
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
   const metrics=await page.locator('.panel[data-mode=static]').evaluate(el=>({n:Number(window.VIS_FEEL.snapshot().n),viewport:innerWidth,phone:el.querySelector('.phone').getBoundingClientRect().width,pitch:Number(el.querySelector('.board').dataset.pitch),token:el.querySelector('.token-art').getBoundingClientRect().width}));measurements.push(metrics);
   const t=(await snap()).targets.hero;const point=page.locator('.panel[data-mode=static] .point[data-x="'+t.x+'"][data-y="'+t.y+'"]');await point.scrollIntoViewIfNeeded();const box=await point.boundingBox();assert.equal(await page.evaluate(([x,y])=>document.elementFromPoint(x,y)?.closest('.point')?.dataset.kind,[box.x+box.width/2,box.y+box.height/2]),'hero');
  });
  await page.locator('.panel[data-mode=static]').screenshot({path:path.join(out,'MOBILE_'+n+'_'+width+'.png')});screenshots.push('MOBILE_'+n+'_'+width+'.png');
 }
 assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(out,'review.json'),JSON.stringify({status:'pass',scope:'offline_visual_comparison_tool',checks:results,desktopMeasurements,measurements,screenshots,page_errors:errors,network_http_requests:requests.filter(u=>/^https?:/.test(u)),human_recognition:'not_run',physical_iphone:'not_run',domain_integration:'not_run',formal_game_ui_integration:'not_run',mage_default_authority:'owner_selected_magic_hand'},null,2)+'\n');
 await browser.close();console.log(JSON.stringify({status:'pass',checks:results.length,screenshots:screenshots.length,measurements}));
}
main().catch(e=>{console.error(e);process.exit(1)});
