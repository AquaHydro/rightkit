// Tests the shipped controller in a fresh VM, with only its browser dependencies mocked.
// Run: node --test website/tests/language.test.mjs
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../src/language.js', import.meta.url), 'utf8');
const locales = ['zh', 'en', 'ja', 'ko'];
const preferenceKey = 'rightkit.website.language';

function browser({ current = 'zh', theme = '', privacy = false, prefix = '',
                   languages = ['en-US'], language = 'en-US', stored = null,
                   storageBlocked = false, query = '', hash = '', configMissing = false } = {}) {
  const root = '/' + (prefix ? prefix + '/' : '') + (theme ? theme + '/' : '');
  const sub = privacy ? 'privacy/' : '';
  const route = (key) => root + (key === 'zh' ? '' : key + '/') + sub;
  const href = 'https://example.test' + route(current) + query + hash;
  const choices = locales.map((key) => ({ key, href: route(key) + (key === 'zh' ? '?lang=zh' : '') }));
  const config = { current, defaultEntry: current === 'zh', languages: choices };
  const events = new Map();
  const writes = [];
  const replacements = [];
  const links = choices.map((choice) => ({
    dataset: { language: choice.key }, href: choice.href, events: new Map(),
    addEventListener(type, listener) { this.events.set(type, listener); },
  }));
  const selectors = [0, 1].map(() => ({
    open: false, focusCount: 0,
    contains(target) { return target === this || target === this.summary; },
    querySelector(name) { assert.equal(name, 'summary'); return this.summary; },
  }));
  for (const selector of selectors) selector.summary = { focus() { selector.focusCount++; } };
  const document = {
    getElementById(id) { assert.equal(id, 'language-data'); return configMissing ? null : { textContent: JSON.stringify(config) }; },
    querySelectorAll(query) { return query === '[data-language]' ? links : selectors; },
    addEventListener(type, listener) { events.set(type, listener); },
  };
  const context = { document, navigator: { languages, language }, URL, URLSearchParams,
    localStorage: {
      getItem(key) { assert.equal(key, preferenceKey); if (storageBlocked) throw new Error('blocked'); return stored; },
      setItem(key, value) { assert.equal(key, preferenceKey); if (storageBlocked) throw new Error('blocked'); writes.push([key, value]); },
    },
    location: { href, hash, replace(value) { replacements.push(value); } },
  };
  vm.runInNewContext(source, context, { filename: 'language.js' });
  events.get('DOMContentLoaded')?.();
  function click(key, overrides = {}) {
    const link = links.find((item) => item.dataset.language === key);
    const event = { button: 0, metaKey: false, ctrlKey: false, shiftKey: false, altKey: false,
                    prevented: false, preventDefault() { this.prevented = true; }, ...overrides };
    link.events.get('click')(event);
    return { href: link.href, event };
  }
  return { links, selectors, events, writes, replacements, click };
}

// Failure and fallback paths first: stale preferences and unavailable storage
// must neither crash startup nor trap people on the Chinese entry.
test('missing configuration leaves unrelated pages alone', () => {
  const result = browser({ configMissing: true });
  assert.deepEqual(result.replacements, []);
  assert.equal(result.events.size, 0);
});

test('invalid stored preference falls back to supported browser preference', () => {
  assert.deepEqual(browser({ stored: 'de', languages: ['fr-FR', 'ko-KR', 'ja-JP'] }).replacements,
                   ['https://example.test/ko/']);
});

test('blocked storage falls back to browser language without throwing', () => {
  assert.deepEqual(browser({ storageBlocked: true, languages: ['ja-JP'] }).replacements,
                   ['https://example.test/ja/']);
});

test('unsupported browser preferences fall back to Chinese without redirect', () => {
  assert.deepEqual(browser({ languages: ['fr-FR', 'de-DE'] }).replacements, []);
  assert.deepEqual(browser({ languages: [] }).replacements, []);
});

test('navigator.language works when navigator.languages is unavailable', () => {
  assert.deepEqual(browser({ languages: null, language: 'ko-KR' }).replacements,
                   ['https://example.test/ko/']);
});

test('region matching considers preferences in order and supports underscores', () => {
  for (const [languages, expected] of [
    [['fr-FR', 'ja-JP', 'en-US'], 'ja'], [['de', 'ko_KR'], 'ko'], [['en-GB', 'ko'], 'en'],
  ]) assert.deepEqual(browser({ languages }).replacements, [`https://example.test/${expected}/`]);
  assert.deepEqual(browser({ languages: ['zh-TW', 'en'] }).replacements, []);
});

test('valid manual preference wins over browser preference', () => {
  assert.deepEqual(browser({ stored: 'ko', languages: ['ja-JP', 'en-US'] }).replacements,
                   ['https://example.test/ko/']);
  assert.deepEqual(browser({ stored: 'zh', languages: ['ja-JP'] }).replacements, []);
});

test('explicit locale routes never redirect even with a conflicting preference', () => {
  for (const current of ['en', 'ja', 'ko'])
    for (const theme of ['', 'ak'])
      for (const privacy of [false, true]) {
        const result = browser({ current, theme, privacy, stored: 'zh', languages: ['ko-KR'] });
        assert.deepEqual(result.replacements, [], `${current}/${theme}/${privacy}`);
      }
});

test('lang=zh keeps the default Chinese route readable without changing preference', () => {
  for (const theme of ['', 'ak'])
    for (const privacy of [false, true]) {
      const result = browser({ theme, privacy, stored: 'ja', query: '?utm=mail&lang=zh', hash: '#help' });
      assert.deepEqual(result.replacements, []);
      assert.deepEqual(result.writes, []);
    }
});

test('automatic negotiation preserves theme, privacy, deployment subpath, query and hash', () => {
  for (const prefix of ['', 'rightkit'])
    for (const theme of ['', 'ak'])
      for (const privacy of [false, true]) {
        const root = '/' + (prefix ? `${prefix}/` : '') + (theme ? `${theme}/` : '');
        const result = browser({ prefix, theme, privacy, languages: ['ko-KR'],
                                 query: '?utm=a&lang=auto&tag=one&tag=two', hash: '#download' });
        assert.deepEqual(result.replacements,
          [`https://example.test${root}ko/${privacy ? 'privacy/' : ''}?utm=a&tag=one&tag=two#download`]);
      }
});

test('manual selection stores preference and uses native anchor navigation', () => {
  const result = browser({ current: 'ja', query: '?utm=mail&lang=zh', hash: '#toolbox' });
  const { href, event } = result.click('ko');
  assert.deepEqual(result.writes, [[preferenceKey, 'ko']]);
  assert.equal(href, 'https://example.test/ko/?utm=mail#toolbox');
  assert.equal(event.prevented, false);
  assert.deepEqual(result.replacements, []);
});

test('blocked persistence still allows manual selection and preserves query/hash', () => {
  const result = browser({ current: 'ko', theme: 'ak', prefix: 'product', privacy: true,
                           storageBlocked: true, query: '?ref=menu', hash: '#settings' });
  const { href, event } = result.click('zh');
  assert.equal(href, 'https://example.test/product/ak/privacy/?ref=menu&lang=zh#settings');
  assert.equal(event.prevented, false);
  assert.deepEqual(result.writes, []);
});

test('manual selection stays in same theme and page kind across every locale', () => {
  for (const current of locales)
    for (const target of locales)
      for (const theme of ['', 'ak'])
        for (const privacy of [false, true]) {
          const result = browser({ current, theme, privacy, prefix: 'site', stored: 'zh', query: '?lang=zh&ref=x', hash: '#main' });
          const chosen = new URL(result.click(target).href);
          assert.equal(chosen.pathname, `/site/${theme ? `${theme}/` : ''}${target === 'zh' ? '' : `${target}/`}${privacy ? 'privacy/' : ''}`);
          assert.equal(chosen.searchParams.get('ref'), 'x');
          assert.equal(chosen.searchParams.get('lang'), target === 'zh' ? 'zh' : null);
          assert.equal(chosen.hash, '#main');
          assert.deepEqual(result.writes, [[preferenceKey, target]]);
        }
});

test('modified clicks leave original href and stored preference unchanged', () => {
  for (const modifier of [{ button: 1 }, { button: 2 }, { metaKey: true },
                          { ctrlKey: true }, { shiftKey: true }, { altKey: true }]) {
    const result = browser({ current: 'ja', query: '?ref=x', hash: '#main' });
    const link = result.links.find((item) => item.dataset.language === 'ko');
    const original = link.href;
    const chosen = result.click('ko', modifier);
    assert.equal(chosen.href, original);
    assert.deepEqual(result.writes, []);
    assert.equal(chosen.event.prevented, false);
  }
});

test('Escape closes open selectors and restores focus to their summaries', () => {
  const result = browser({ current: 'ja' });
  result.selectors[0].open = true;
  const event = { key: 'Escape', prevented: false, preventDefault() { this.prevented = true; } };
  result.events.get('keydown')(event);
  assert.equal(result.selectors[0].open, false);
  assert.equal(result.selectors[0].focusCount, 1);
  assert.equal(result.selectors[1].focusCount, 0);
  assert.equal(event.prevented, true);
});

test('outside click closes selectors, inside click keeps its selector open', () => {
  const result = browser({ current: 'ja' });
  result.selectors.forEach((selector) => { selector.open = true; });
  result.events.get('click')({ target: result.selectors[0].summary });
  assert.equal(result.selectors[0].open, true);
  assert.equal(result.selectors[1].open, false);
  result.events.get('click')({ target: {} });
  assert.equal(result.selectors[0].open, false);
  assert.equal(result.selectors[0].focusCount, 0);
});
