// Website adapter. Reads the real website sources (read-only) and exposes them as HTML strings:
// - Finder window markup: website/src/index.html (.finder block)
// - Menu contents: buildMenu() and iconHTML() from website/src/main.js, run with a no-op `act`
// - Demo data and copy: website/content.json
// - Shortcuts action names: RightKit/Intents/Intents.swift
// Styles come from website/src/styles.css, loaded by build.mjs.
import fs from 'node:fs';
import path from 'node:path';
import content from '../../../content.json';

const WEB = path.resolve('../..');
const read = (file) => fs.readFileSync(path.join(WEB, file), 'utf8');
const mainJs = read('src/main.js');
const indexHtml = read('src/index.html');

export const t = content.zh;
export const demo = t.demo;

// Cut a span of source text from `start` to the end of `end`; fail loudly when the website changes shape.
function grab(text, start, end) {
  const i = text.indexOf(start);
  const j = text.indexOf(end, i);
  if (i < 0 || j < 0) throw new Error(`website source changed: cannot find ${start}`);
  return text.slice(i, j + end.length);
}

const fromMain = [
  grab(mainJs, 'const svg = ', ';\n'),
  grab(mainJs, 'const escapeHTML = ', ';\n'),
  grab(mainJs, 'const docColors = ', ';\n'),
  grab(mainJs, 'const displayName = ', ';\n'),
  grab(mainJs, 'const iconHTML = ', '\n  };\n'),
  grab(mainJs, 'function buildMenu(target) {', '\n    return items;\n  }'),
].join('\n');
const noop = new Proxy({}, {get: () => () => {}});
const lib = new Function('data', 'toolGroups', 'act', `${fromMain}\nreturn {svg, escapeHTML, iconHTML, displayName, buildMenu};`)(demo, t.toolbox.groups, noop);
export const {svg, escapeHTML} = lib;

// SVG sprite with the menu icons.
export const sprite = grab(indexHtml, '<svg class="sprite"', '</svg>');

// Minimal subset of website/build.py's template syntax, enough for the Finder block.
const lookup = (p) => p.split('.').slice(1).reduce((v, k) => v[k], t);
function fill(tpl, scope = {}) {
  return tpl
    .replace(/\{% for (\w+) in ([\w.]+) %\}([\s\S]*?)\{% endfor %\}/g, (_, name, list, body) =>
      lookup(list).map((item) => fill(body.replace(new RegExp(`\\{\\{ ${name}\\.(\\w+) \\}\\}`, 'g'), (_, k) => escapeHTML(String(item[k]))))).join(''))
    .replace(/\{\{ ([\w.]+) \}\}/g, (_, p) => escapeHTML(String(lookup(p))));
}
const finderTpl = grab(indexHtml, '<div class="finder" data-finder', '</ul>\n                <div class="toast"');

// files: [{name, kind, ext, attrs}] where attrs are extra data-* attributes for the timeline.
// toasts: [{text, attrs}]
export function finderHTML({files, toasts = [], sideAttrs = {}}) {
  const items = files.map((file) => {
    const attrs = attr(file.attrs);
    return `<li><button type="button" class="file" data-name="${escapeHTML(file.name)}"${attrs}><span class="file-icon">${lib.iconHTML(file)}</span><span class="file-name">${escapeHTML(lib.displayName(file))}</span></button></li>`;
  }).join('');
  let html = fill(finderTpl).replace('<ul class="files" data-files>', `<ul class="files" data-files>${items}`);
  html = html.replace(/<div class="toast"$/, '');
  for (const [place, a] of Object.entries(sideAttrs)) html = html.replace(`<li data-place="${place}"`, `<li data-place="${place}"${attr(a)}`);
  const toastHTML = toasts.map((x) => `<div class="toast" role="status"${attr(x.attrs)}>${escapeHTML(x.text)}</div>`).join('');
  return `${html}${toastHTML}</div></div></div>`;
}

function attr(a = {}) {
  return Object.entries(a).map(([k, v]) => ` data-${k}="${escapeHTML(String(v))}"`).join('');
}

// Same markup as openMenu() in main.js. rowAttrs(title) returns extra data-* for a row.
export function menuHTML(items, {id, attrs = {}, rowAttrs = () => ({}), extraClass = ''}) {
  const rows = items.map((item) => {
    if (item.sep) return `<div class="msep" role="separator"></div>`;
    const lead = item.real || (item.icon ? lib.svg(item.icon) : '');
    return `<div class="mi" role="menuitem" data-key="${id}/${escapeHTML(item.title)}"${attr(rowAttrs(item.title))}>${lead}<span class="t">${escapeHTML(item.title)}</span>${item.children ? lib.svg('chevron', 'ic chev') : ''}</div>`;
  }).join('');
  return `<div class="menu ${extraClass}" role="menu" id="${id}"${attr(attrs)}>${rows}</div>`;
}

// buildMenu(target) returns the F-061 menu for a demo file (or null for blank space).
export const fileByName = (name) => demo.files.find((f) => f.name === name);
export const menuFor = (name) => lib.buildMenu(name ? fileByName(name) : null);
export const submenu = (items, title) => items.find((i) => i.title === title).children;

// App Intent titles, in declaration order (F-074).
export const intentTitles = [...fs.readFileSync(path.resolve(WEB, '../RightKit/Intents/Intents.swift'), 'utf8')
  .matchAll(/static let title: LocalizedStringResource = "([^"]+)"/g)].map((m) => m[1]);
