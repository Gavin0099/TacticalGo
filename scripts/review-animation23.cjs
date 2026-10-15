// Executes the browser comparison only. Native AVAudioPlayer/store tests remain separate.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs'), path = require('node:path');
const out = path.resolve(__dirname, '../artifacts/animation-23');
(async () => {
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch({ channel: 'chrome', headless: true, args: ['--autoplay-policy=no-user-gesture-required'] });
  const context = await browser.newContext({ viewport: { width: 1100, height: 940 } });
  const page = await context.newPage(), errors = [], checks = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('response', r => { if (r.status() >= 400) errors.push(r.status() + ' ' + r.url()); });
  try {
    await page.goto('http://127.0.0.1:8771/tools/animation-23/');
    await page.waitForSelector('body[data-ready=true]');
    assert.equal(await page.locator('#sound').isChecked(), false);
    for (const width of ['375', '402']) {
      await page.selectOption('#width', width);
      for (let i = 0; i < 7; i++) {
        await page.locator(`[data-skill="${i}"]`).click();
        await page.evaluate(() => preview.seek(preview.timings[preview.model.index].candidateInputEnd));
        assert.match(await page.locator('#after-ready').innerText(), /可操作/);
        assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
        assert.equal(Math.round((await page.locator('#after').boundingBox()).width), +width);
        checks.push({ width: +width, skill: i, check: 'source visual end reports ready; board fits', passed: true });
      }
    }
    // Independent known durations: chain visual .70; existing B WAV 1.219 + .06 start.
    await page.locator('[data-skill="5"]').click();
    await page.locator('#sound').check();
    await page.locator('#replay').click();
    assert.equal(await page.evaluate(() => preview.follow()), false);
    await page.waitForFunction(() => preview.model.elapsed >= .78);
    assert.equal(await page.evaluate(() => preview.model.playing), true);
    assert.equal(await page.evaluate(() => preview.voiceCount()), 1);
    assert.match(await page.locator('#before-ready').innerText(), /等待/);
    assert.match(await page.locator('#after-ready').innerText(), /可操作/);
    await page.locator('main').screenshot({ path: path.join(out, 'rogue-ready-during-voice.png') });
    assert.equal(await page.evaluate(() => preview.follow()), true);
    assert.equal(await page.evaluate(() => preview.voiceCount()), 1);
    await page.waitForTimeout(700);
    assert.equal(await page.evaluate(() => preview.voiceCount()), 0);
    assert.match(await page.locator('#before-ready').innerText(), /可操作/);
    checks.push({ check: 'chain unlocks while real browser WAV plays; next-hand probe retains it until natural end', passed: true });

    await page.locator('#replay').click();
    await page.waitForFunction(() => preview.model.elapsed >= .78);
    await page.locator('#cancel').click();
    assert.equal(await page.evaluate(() => preview.voiceCount()), 0);
    const generation = await page.evaluate(() => preview.model.generation);
    await page.waitForTimeout(650);
    assert.equal(await page.evaluate(() => preview.model.generation), generation);
    assert.equal(await page.evaluate(() => preview.model.phase), 'ready');
    checks.push({ check: 'undo-style full cancellation stops retained WAV and stale timers', passed: true });

    await page.locator('#replay').click();
    await page.waitForFunction(() => preview.model.elapsed >= .78);
    await page.evaluate(() => { preview.model.index = 2; preview.play(); });
    assert.equal(await page.evaluate(() => preview.voiceCount()), 0);
    await page.waitForTimeout(130);
    assert.equal(await page.evaluate(() => preview.voiceCount()), 1);
    checks.push({ check: 'new skill stops old voice before scheduling new one', passed: true });
    await page.evaluate(() => preview.stop());
    await page.waitForTimeout(1300);
    assert.equal(await page.evaluate(() => preview.voiceCount()), 0);
    assert.equal(await page.evaluate(() => preview.model.phase), 'ready');
    checks.push({ check: 'background-style stop cannot revive voice or rendering', passed: true });

    await page.locator('#sound').uncheck();
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.waitForFunction(() => document.querySelector('#reduced').checked);
    assert.equal(await page.locator('#reduced').isChecked(), true);
    await page.locator('[data-skill="6"]').click();
    await page.evaluate(() => preview.seek(.94));
    assert.match(await page.locator('#after-ready').innerText(), /可操作/);
    checks.push({ check: 'reduced motion retains final result and visual-end input timing', passed: true });
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    await page.waitForFunction(() => !document.querySelector('#reduced').checked);
    for (let i = 0; i < 7; i++) {
      await page.locator(`[data-skill="${i}"]`).click();
      await page.locator('#replay').click();
      await page.waitForFunction(() => !preview.model.playing && preview.model.phase === 'landed');
      assert.match(await page.locator('#before-ready').innerText(), /可操作/);
      checks.push({ skill: i, check: 'normal-speed comparison finishes both windows', passed: true });
    }
    await page.setViewportSize({ width: 375, height: 900 });
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    checks.push({ check: 'review page fits phone', passed: true });
    assert.deepEqual(errors, []);
    assert.equal(await page.evaluate(() => preview.model.audioError ?? null), null);
    fs.writeFileSync(path.join(out, 'browser-checks.json'), JSON.stringify({ evidence: 'Canvas + real HTMLAudioElement WAV playback; no native execution or listening verdict', checks, errors, nativeBuild: 'NOT RUN', nativeTests: 'NOT RUN', deviceLatency: 'NOT RUN' }, null, 2) + '\n');
    console.log(`PASS: ${checks.length} browser cases. Swift/native audio/input latency NOT RUN.`);
  } finally { await context.close(); await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
