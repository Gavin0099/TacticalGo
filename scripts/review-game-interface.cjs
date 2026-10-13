// Browser design fixture checks only. These do not execute SwiftUI or Domain rules.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const out = path.join(root, process.env.INTERFACE_EVIDENCE_DIR || 'artifacts/game-interface-19');
const url = process.env.INTERFACE_PREVIEW_URL || 'http://127.0.0.1:8771/tools/game-interface-preview/';
const checks = [], errors = [];
(async () => {
  fs.mkdirSync(out, {recursive:true});
  const browser = await chromium.launch({channel:'chrome', headless:true});
  try {
    const page = await browser.newPage({viewport:{width:1440,height:1120},deviceScaleFactor:2});
    page.on('pageerror', e=>errors.push(e.message));
    page.on('response', r=>{if(r.status()>=400) errors.push(`${r.status()} ${r.url()}`);});
    await page.goto(url);
    await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));
    for (const width of [375,402]) {
      await page.locator(`[data-width="${width}"]`).click();
      for (const hero of ['warrior','mage','rogue','priest']) {
        await page.locator(`[data-select-hero="${hero}"]`).click();
        let boardRect;
        for (const screen of ['ready','preview','loot','locked','result','lobby']) {
          await page.locator(`[data-screen="${screen}"]`).click();
          const bounds = await page.locator('#device').evaluate(e=>({w:e.clientWidth,scroll:e.scrollWidth}));
          assert.equal(bounds.scroll, bounds.w, `${hero}/${screen} horizontal overflow`);
          if (screen!=='lobby') {
            const dock=await page.locator('#device .dock').boundingBox();
            const board=await page.locator('#device .board').boundingBox();
            assert.equal(dock.height,200);
            if(boardRect) assert.deepEqual(board,boardRect, `${hero}/${screen} moved board`);
            else boardRect=board;
            const buttons=await page.locator('#device .dock button').evaluateAll(es=>es.map(e=>({width:e.getBoundingClientRect().width,height:e.getBoundingClientRect().height,text:e.textContent.trim()})));
            for(const b of buttons) {assert.ok(b.width>=44, JSON.stringify(b));assert.ok(b.height>=44,JSON.stringify(b));}
            if(screen==='locked') assert.equal(await page.locator('#device .ability:enabled,#device .commands button:enabled').count(),0);
            if(screen==='result') {assert.equal(await page.locator('#device .ability').count(),0);assert.equal(await page.locator('#device [data-action="replay"]').count(),1);}
          }
          checks.push({width,hero,screen,pass:true});
        }
      }
      await page.locator('[data-screen="directions"]').click();
      assert.equal(await page.locator('#device [data-direction]').count(),4);
      assert.equal(await page.locator('#device [data-direction]:disabled').count(),1);
      checks.push({width,hero:'mage',screen:'directions',pass:true});
    }
    await page.locator('[data-width="402"]').click();
    await page.locator('[data-screen="ready"]').click();
    assert.equal(await page.locator('#device [data-action="confirm"]').isEnabled(),false);
    await page.locator('#device [data-mode="skill"]').click();
    await page.locator('#device [data-action="target"]').click();
    assert.equal(await page.locator('#device [data-action="confirm"]').isEnabled(),true);
    const resources=await page.locator('#device .resources').innerText();
    await page.locator('#device [data-action="cancel"]').click();
    assert.equal(await page.locator('#device .resources').innerText(),resources,'Cancel consumed fixture resources');
    assert.equal(await page.locator('#device [data-action="confirm"]').isEnabled(),false);
    await page.locator('#device [data-action="target"]').click();
    await page.locator('#device [data-action="confirm"]').click();
    assert.match(await page.locator('#device .resources').innerText(),/1 AP/);
    assert.match(await page.locator('#device .resources').innerText(),/能量 3\/6/);
    await page.locator('#device [data-action="cancel"]').click();
    assert.equal(await page.locator('#device .resources').innerText(),resources);
    await page.locator('#device [data-mode="advanced"]').click();
    await page.locator('#device [data-action="target"]').click();
    await page.locator('#device [data-action="confirm"]').click();
    assert.match(await page.locator('#device .resources').innerText(),/能量 1\/6/);
    await page.locator('#device [data-action="target"]').click();
    assert.equal(await page.locator('#device [data-action="confirm"]').isEnabled(),false,'Insufficient fixture resources must not allow confirm');
    await page.locator('[data-screen="loot"]').click();
    await page.locator('#device [data-action="loot"]').click();
    await page.waitForFunction(()=>document.querySelector('#device .rail').scrollLeft>0);
    assert.equal(await page.locator('#device [data-mode="shadow"]').isEnabled(),false);
    await page.locator('#device [data-mode="slime"]').click();
    assert.equal(await page.locator('#device [data-mode="slime"]').getAttribute('aria-pressed'),'true');
    await page.locator('#device .dock [data-action="help"]').click();
    assert.equal(await page.locator('dialog').evaluate(e=>e.open),true);
    await page.keyboard.press('Escape');
    assert.equal(await page.locator('dialog').evaluate(e=>e.open),false);
    await page.emulateMedia({reducedMotion:'reduce'});
    assert.equal(await page.locator('.target').first().evaluate(e=>getComputedStyle(e).animationName),'none');
    await page.locator('[data-screen="result"]').click();
    await page.locator('#device [data-action="replay"]').focus();
    await page.keyboard.press('Enter');
    assert.equal(await page.locator('#device .ability').count(),4);
    const screenshots=[];
    for(const [width,screen,name] of [[402,'preview','candidate-402-preview'],[375,'ready','candidate-375-ready'],[375,'result','candidate-375-result'],[375,'lobby','candidate-375-lobby'],[402,'lobby','candidate-402-lobby']]){
      await page.locator(`[data-width="${width}"]`).click();
      await page.locator(`[data-screen="${screen}"]`).click();
      await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));
      await page.locator('#device').screenshot({path:path.join(out,name+'.png')});screenshots.push(name+'.png');
    }
    await page.locator('[data-width="402"]').click();await page.locator('[data-screen="preview"]').click();
    await page.screenshot({path:path.join(out,'candidate-overview.png'),fullPage:true});
    await page.locator('#device .dock').screenshot({path:path.join(out,'candidate-action-dock.png')});
    await page.locator('#class-gallery').screenshot({path:path.join(out,'candidate-four-classes.png')});
    screenshots.push('candidate-overview.png','candidate-four-classes.png','candidate-action-dock.png');
    if(await page.locator('.glyph-diagnostics').count()) {
      const cells = await page.locator('.glyph-diagnostics .icon').evaluateAll(es=>es.map(e=>({size:e.getBoundingClientRect().width,position:getComputedStyle(e).backgroundPosition})));
      for(const size of [32,48,64]) {
        const row=cells.filter(c=>c.size===size);
        assert.equal(row.length,7);assert.equal(new Set(row.map(c=>c.position)).size,7,'Seven distinct art cells');
      }
      await page.locator('.glyph-diagnostics').screenshot({path:path.join(out,'seven-skills-32-48-64.png')});
      screenshots.push('seven-skills-32-48-64.png');
    }
    await page.setViewportSize({width:375,height:900});
    const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth);
    assert.equal(overflow,false,'Review page should fit a phone browser');
    assert.deepEqual(errors,[]);
    const report={evidence:'browser-design-fixture',nativeBuild:'NOT RUN',nativeTests:'NOT RUN',checks,interactions:['preview','cancel retains resources','confirm changes fixture resource display','undo restores fixture display','insufficient fixture resources reject confirm','loot scroll and unlock state','help and Escape','reduced motion','keyboard replay'],screenshots,errors};
    fs.writeFileSync(path.join(out,'browser-checks.json'),JSON.stringify(report,null,2)+'\n');
    console.log(`PASS: ${checks.length} layout cases; 9 fixture interaction checks; no browser errors. Native SwiftUI NOT RUN.`);
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
