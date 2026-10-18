import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { browser, config } from '../test-support/browser.js';
import { startPreview } from '../src/app.js';

const readSource = name => readFile(new URL(`../src/${name}`, import.meta.url), 'utf8');
test('generic metadata never changes to shared schedule content', async t => {
  const window = await browser(t);
  const head = window.document.head.innerHTML;
  await startPreview({ window, config });
  assert.equal(window.document.head.innerHTML, head);
  assert.match(window.document.title, /Schediel/);
  assert.equal(window.document.querySelector('meta[name=referrer]').content, 'no-referrer');
  assert.equal(window.document.querySelector('meta[name=robots]').content, 'noindex, nofollow, noarchive');
});

test('HTML uses only self-hosted module/CSS, no inline handlers or third-party resources', async t => {
  const window = await browser(t);
  const document = window.document;
  assert.equal(document.documentElement.lang, 'en');
  assert.ok(document.querySelector('meta[name=viewport]'));
  assert.equal(document.querySelectorAll('main h1').length, 1);
  assert.equal(document.querySelector('main').getAttribute('aria-labelledby'), 'page-title');
  assert.equal(document.querySelector('[role=status]').getAttribute('aria-live'), 'polite');
  for (const element of document.querySelectorAll('*')) {
    for (const attr of element.attributes) assert.equal(/^on/i.test(attr.name), false);
    for (const attr of ['src', 'href']) {
      if (element.hasAttribute(attr)) assert.match(element.getAttribute(attr), /^\/assets\/[a-z.]+$/);
    }
  }
  assert.equal(document.querySelectorAll('script').length, 1);
  assert.equal(document.querySelector('script').type, 'module');
  assert.equal(document.querySelector('script').textContent, '');
  assert.equal(document.querySelector('style, iframe, object, embed, form, img'), null);
  const policy = document.querySelector('meta[http-equiv="Content-Security-Policy"]').content;
  for (const directive of ["default-src 'none'", "script-src 'self'", "style-src 'self'", "img-src 'self' data:", "base-uri 'none'", "form-action 'none'"]) assert.ok(policy.includes(directive), directive);
  assert.doesNotMatch(policy, /unsafe-inline|unsafe-eval|https:|\*/);
});

test('module entry actually wires configured settings to the browser controller', async () => {
  const entry = await readSource('main.js').catch(error => error.code === 'ENOENT' ? '' : Promise.reject(error));
  assert.match(entry, /import.*config.*['"]\.\/config\.js['"]/);
  assert.match(entry, /import.*startPreview.*['"]\.\/app\.js['"]/);
  assert.match(entry, /await startPreview\(\{ window, config \}\)/);
});

test('styles use the design tokens, accessible controls, dark mode and reduced motion', async () => {
  const css = await readSource('style.css').catch(error => error.code === 'ENOENT' ? '' : Promise.reject(error));
  for (const token of ['#F5F5F7', '#1D1D1F', '#FFFFFF', '#5A5A60', '#0066CC', '#0C0C0E', '#1C1C1E', '#B2B2BA', '#64A7FF', '#081322']) assert.ok(css.toUpperCase().includes(token.toUpperCase()), token);
  assert.match(css, /font-family:\s*system-ui/);
  assert.match(css, /prefers-color-scheme:\s*dark/);
  assert.match(css, /prefers-reduced-motion:\s*reduce/);
  assert.match(css, /min-block-size:\s*48px/);
  assert.match(css, /min-inline-size:\s*44px/);
  assert.match(css, /:focus-visible/);
  assert.match(css, /outline:\s*3px/);
  assert.match(css, /overflow-wrap:\s*anywhere/);
  assert.match(css, /\[hidden\]\s*\{\s*display:\s*none\s*!important/);
  assert.doesNotMatch(css, /@import|https?:\/\/|url\(|@font-face/);
});
