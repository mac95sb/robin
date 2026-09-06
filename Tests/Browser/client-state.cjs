// Generate the fixture: ROBIN_STATE_BROWSER_OUTPUT=/tmp/robin-state mise run test
// With Playwright available: node Tests/Browser/client-state.cjs /tmp/robin-state/.robin/build
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright');
(async () => {
  const root = path.resolve(process.argv[2]);
  const server = http.createServer(async (req, res) => {
    const pathname = new URL(req.url, 'http://localhost').pathname;
    let file = path.resolve(root, '.' + pathname, pathname.endsWith('/') ? 'index.html' : '');
    if (!file.startsWith(root + path.sep)) { res.writeHead(403).end(); return; }
    try {
      if ((await fs.stat(file)).isDirectory()) file = path.join(file, 'index.html');
      res.setHeader('Content-Type', file.endsWith('.js') ? 'text/javascript' : file.endsWith('.css') ? 'text/css' : 'text/html');
      res.end(await fs.readFile(file));
    } catch { res.writeHead(404).end(); }
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  let browser;
  try {
    browser = await chromium.launch({headless: true, executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE});
    const url = `http://127.0.0.1:${server.address().port}/`;
    const page = await browser.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    await page.goto(url);
    const first = page.locator('#first'), second = page.locator('#second');
    const count = first.getByRole('spinbutton', {name: 'Count', exact: true});
    const click = name => first.getByRole('button', {name, exact: true}).click();
    // One event can update all scalar types; invalid batches commit nothing.
    assert.equal(await first.getByText('Unsaved changes', {exact:true}).isVisible(), false);
    await click('Invalid batch');
    assert.equal(await count.inputValue(), '0');
    assert.equal(await first.getByRole('textbox', {name:'Name',exact:true}).inputValue(), 'Robin');
    await click('Apply values');
    assert.equal(await count.inputValue(), '42');
    assert.equal(await first.getByRole('spinbutton', {name:'Fraction',exact:true}).inputValue(), '19.95');
    assert.equal(await first.getByRole('textbox', {name:'Name',exact:true}).inputValue(), 'Robin updated');
    assert.equal(await first.getByText('Details', {exact:true}).isVisible(), false);
    await click('Toggle visibility');
    await click('Read current values');
    assert.equal(await count.inputValue(), '9');
    assert.equal(await first.getByRole('textbox', {name:'Name',exact:true}).inputValue(), 'Robin updated Swift');
    await click('Reset form');
    assert.equal(await first.getByRole('spinbutton', {name:'Edits',exact:true}).inputValue(), '0');
    await click('+10'); assert.equal(await count.inputValue(), '10');
    assert.equal(await second.getByRole('spinbutton', {name:'Count',exact:true}).inputValue(), '0');
    await click('−10'); assert.equal(await count.inputValue(), '0');
    await count.fill('32'); assert.equal(await first.locator('[data-robin-text]').first().textContent(), '32');
    await count.fill(''); assert.equal(await first.locator('[data-robin-text]').first().textContent(), '32');
    await click('+1'); assert.equal(await count.inputValue(), '33');
    await click('Reset count'); assert.equal(await count.inputValue(), '0');
    await first.getByRole('textbox', {name:'Name'}).fill('Typed <script> text');
    assert.equal(await first.getByRole('spinbutton', {name:'Edits',exact:true}).inputValue(), '1');
    assert.equal(await first.getByText('Unsaved changes', {exact:true}).isVisible(), false);
    await first.getByRole('textbox', {name:'Name'}).blur();
    assert.equal(await first.getByText('Unsaved changes', {exact:true}).isVisible(), true);
    assert.equal(await first.getByRole('textbox', {name:'Summary',exact:true}).inputValue(), 'Typed <script> text!');
    assert.equal(await first.locator('[data-robin-text]').nth(1).textContent(), 'Typed <script> text');
    await click('Set name');
    assert.equal(await first.getByRole('textbox', {name:'Name'}).inputValue(), '<b>Safe & plain</b>');
    assert.equal(await first.locator('b').count(), 0);
    await click('Toggle visibility'); assert.equal(await first.getByText('Details', {exact:true}).isVisible(), false);
    await click('Toggle visibility'); assert.equal(await first.getByText('Details', {exact:true}).isVisible(), true);
    await first.getByRole('checkbox', {name:'Locked'}).check();
    assert.equal(await first.getByRole('button', {name:'Guarded increment'}).isDisabled(), true);
    await click('+0.5'); assert.equal(await first.getByRole('spinbutton', {name:'Fraction'}).inputValue(), '1');
    await click('Overflow'); assert.equal(await first.getByRole('spinbutton', {name:'Limit'}).inputValue(), '9007199254740991');
    await click('Reset form');
    assert.equal(await first.getByRole('textbox', {name:'Name'}).inputValue(), 'Robin');
    assert.equal(await first.getByRole('button', {name:'Guarded increment'}).isDisabled(), false);
    // A cancelled form reset must not reset bound state.
    await click('+10');
    await first.locator('form').evaluate(form => form.addEventListener('reset', event => event.preventDefault(), {once:true}));
    await click('Reset form'); assert.equal(await count.inputValue(), '10');
    // Replaced regions retain current state and initialize new bound elements.
    await first.getByRole('textbox', {name:'Name'}).fill('Preserved');
    await first.locator('[data-robin-text]').nth(1).evaluate(element => element.replaceWith(element.cloneNode(true)));
    assert.equal(await first.locator('[data-robin-text]').nth(1).textContent(), 'Preserved');
    assert.deepEqual(errors, []);
    const noJS = await browser.newPage({javaScriptEnabled:false});
    await noJS.goto(url);
    assert.equal(await noJS.locator('#first').getByRole('spinbutton', {name:'Count',exact:true}).inputValue(), '0');
    assert.equal(await noJS.locator('#first [data-robin-text]').first().textContent(), '0');
    if (process.argv.includes('--navigation')) {
      const navigation = await browser.newPage();
      await navigation.goto(url + 'plain/');
      await navigation.evaluate(() => { window.beforeNavigation = true; });
      await navigation.getByRole('link', {name:'Counter page',exact:true}).click();
      await navigation.waitForURL(url);
      await navigation.waitForLoadState('load');
      assert.equal(await navigation.evaluate(() => window.beforeNavigation), undefined);
      await navigation.locator('#first').getByRole('button', {name:'+10',exact:true}).click();
      await navigation.getByRole('link', {name:'Plain page',exact:true}).click();
      await navigation.getByRole('link', {name:'Counter page',exact:true}).waitFor();
      await navigation.getByRole('link', {name:'Counter page',exact:true}).click();
      const nextCount = navigation.locator('#first').getByRole('spinbutton', {name:'Count',exact:true});
      await nextCount.waitFor();
      assert.equal(await nextCount.inputValue(), '0');
      await navigation.locator('#first').getByRole('button', {name:'+1',exact:true}).click();
      assert.equal(await nextCount.inputValue(), '1');
    }
    console.log('Client state: operations, isolation, inputs, safe text, visibility, disabled state, numeric limits, reset and no-JS rendering passed.');
  } finally {
    await browser?.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
