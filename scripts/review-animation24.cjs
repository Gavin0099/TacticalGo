// Browser comparison only: existing motion coverage plus AV24 ground-contact rendering checks.
const {spawnSync}=require('node:child_process'),path=require('node:path'),fs=require('node:fs'),assert=require('node:assert/strict');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..'),out=path.join(root,'artifacts/animation-24');
const base=spawnSync(process.execPath,[path.join(__dirname,'review-animation21.cjs')],{env:{...process.env,ANIMATION_PREVIEW_URL:'http://127.0.0.1:8771/tools/animation-24/',ANIMATION_EVIDENCE_DIR:'artifacts/animation-24'},encoding:'utf8'});
process.stdout.write(base.stdout);process.stderr.write(base.stderr);if(base.status!==0)process.exit(base.status||1);
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true}),page=await browser.newPage({viewport:{width:1100,height:940}}),errors=[],checks=[];
 page.on('pageerror',e=>errors.push(e.message));
 try{
  await page.goto('http://127.0.0.1:8771/tools/animation-24/');await page.waitForSelector('body[data-ready=true]');
  const beats=await page.evaluate(()=>preview.contacts.beats(preview.fixtures.find(f=>f.id==='chain')));
  assert.deepEqual(beats.map(b=>b.at),[[4,4],[5,4],[5,4],[5,3]]);
  beats.slice(0,2).forEach(b=>assert.ok(Math.abs(b.start-.26)<1e-9));beats.slice(2).forEach(b=>assert.equal(b.start,.36));
  checks.push({check:'chain has two exchanges at four actual sockets, .26 and .36',passed:true});
  const invalid=await page.evaluate(()=>{const C=preview.contacts;return [-1,NaN,Infinity,.70,.44].map(t=>C.frame(t,.26,.70).opacity).concat([C.frame(.26,.26,.70,true).opacity,C.frame(.26,.70,.26).opacity])});
  assert.deepEqual(invalid,[0,0,0,0,0,0,0]);checks.push({check:'contact has no late/invalid/reduced residue',passed:true});
  // Pixel comparisons execute actual Canvas output; they demonstrate visibility, not aesthetic parity.
  for(const width of ['375','402']){
   await page.selectOption('#width',width);
   for(let i=0;i<7;i++){
    await page.locator(`[data-skill="${i}"]`).click();
    const result=await page.evaluate(()=>{
     const f=preview.fixtures[preview.model.index],C=preview.contacts;
     preview.seek(f.kind==='chain'?.26:f.arrival);
     const a=document.querySelector('#before').getContext('2d').getImageData(0,0,document.querySelector('#before').width,document.querySelector('#before').height).data;
     const b=document.querySelector('#after').getContext('2d').getImageData(0,0,document.querySelector('#after').width,document.querySelector('#after').height).data;
     let changed=0;for(let j=0;j<a.length;j+=4)if(Math.abs(a[j]-b[j])+Math.abs(a[j+1]-b[j+1])+Math.abs(a[j+2]-b[j+2])>24)changed++;
     return {id:f.id,changed,points:C.beats(f).map(b=>b.at),timing:[f.arrival,f.duration]};
    });
    assert.ok(result.changed>20,`${result.id}: ground contact not visible`);
    checks.push({width:+width,...result,check:'contact changes visible pixels at normal phone scale',passed:true});
    if(width==='375'&&[0,2,5,6].includes(i))await page.locator('main').screenshot({path:path.join(out,`contact-${result.id}.png`)});
    if(i===5){await page.evaluate(()=>preview.seek(.36));if(width==='375')await page.locator('main').screenshot({path:path.join(out,'chain-second.png')})}
    await page.evaluate(()=>preview.seek(preview.fixtures[preview.model.index].duration));
    assert.equal(await page.evaluate(()=>document.querySelector('#before').toDataURL()===document.querySelector('#after').toDataURL()),true);
    checks.push({width:+width,id:result.id,check:'exact same resting canvas after end',passed:true});
   }
  }
  await page.locator('#dense').check();await page.selectOption('#width','375');await page.locator('[data-skill="2"]').click();await page.evaluate(()=>preview.seek(.68));
  await page.locator('main').screenshot({path:path.join(out,'dense-contact.png')});
  await page.emulateMedia({reducedMotion:'reduce'});await page.waitForFunction(()=>document.querySelector('#reduced').checked);
  await page.evaluate(()=>preview.seek(.68));
  assert.equal(await page.evaluate(()=>document.querySelector('#before').toDataURL()===document.querySelector('#after').toDataURL()),true);
  checks.push({check:'reduced motion has identical final board and no new accent',passed:true});
  await page.emulateMedia({reducedMotion:'no-preference'});await page.waitForFunction(()=>!document.querySelector('#reduced').checked);
  await page.locator('[data-skill="5"]').click();await page.locator('#sound').check();await page.locator('#replay').click();
  await page.waitForFunction(()=>preview.model.time>=.29);
  assert.ok(await page.evaluate(()=>preview.activeAudio()>0),'Real browser WAV must be playing');
  await page.waitForFunction(()=>preview.model.phase==='landed');
  const contactAudio=await page.evaluate(()=>preview.model.cueTimes.filter(c=>c.file==='P08/p8-rogue-land.wav'));
  assert.equal(contactAudio.length,2);assert.deepEqual(contactAudio.map(c=>c.scheduled).sort(),[.26,.36]);
  assert.ok(contactAudio[0].started<contactAudio[1].started);assert.deepEqual(await page.evaluate(()=>preview.model.audioErrors),[]);
  checks.push({check:'chain schedules two independent real browser contact WAV starts',contactAudio,passed:true});
  assert.deepEqual(errors,[]);
  fs.writeFileSync(path.join(out,'contact-checks.json'),JSON.stringify({evidence:'browser-only Canvas rendering; no native receipt/Swift/audio execution',checks,errors,nativeBuild:'NOT RUN',quality90Percent:'NOT ESTABLISHED'},null,2)+'\n');
  console.log(`PASS: ${checks.length} additional contact/rendering cases; 90% quality NOT ESTABLISHED.`);
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
