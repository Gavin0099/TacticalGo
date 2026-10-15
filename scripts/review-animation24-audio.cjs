// Real browser WAV scheduling/relative gain only; no listening verdict or native validation.
const {chromium}=require('playwright'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true}),page=await browser.newPage();
 try{
  await page.goto('http://127.0.0.1:8771/tools/animation-24/');await page.waitForSelector('body[data-ready=true]');
  await page.locator('[data-skill="5"]').click();await page.locator('#sound').check();await page.locator('#replay').click();
  await page.waitForFunction(()=>preview.model.time>=.29);
  const first=await page.evaluate(()=>preview.audioSamples().filter(s=>s.src.endsWith('p8-rogue-land.wav')));
  assert.equal(first.length,1);assert.ok(Math.abs(first[0].volume-.38*.60)<1e-6);
  await page.waitForFunction(()=>preview.model.phase==='landed');
  const cues=await page.evaluate(()=>preview.model.cueTimes.filter(c=>c.file.endsWith('p8-rogue-land.wav')));
  assert.equal(cues.length,2);assert.deepEqual(cues.map(c=>c.scheduled).sort(),[.26,.36]);
  assert.deepEqual(await page.evaluate(()=>preview.model.audioErrors),[]);
  fs.writeFileSync(path.resolve(__dirname,'../artifacts/animation-24/audio-gain-check.json'),JSON.stringify({evidence:'browser HTMLAudioElement scheduling/gain only',first,cues,passed:true,listening:'NOT RUN',native:'NOT RUN'},null,2)+'\n');
  console.log('PASS: two browser contact starts, first-contact relative gain 60%; listening/native NOT RUN.');
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
