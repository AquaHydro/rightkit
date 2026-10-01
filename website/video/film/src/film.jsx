import React from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import {t, demo, sprite, finderHTML, menuHTML, menuFor, submenu, intentTitles, escapeHTML} from './site-adapter.jsx';

const html = (s) => ({dangerouslySetInnerHTML: {__html: s}});
const fmt = (tpl, v) => tpl.replace(/\{(\w+)\}/g, (_, k) => v[k] ?? '');
const file = (name) => `.file[data-name="${name}"]`;
const row = (key) => `[data-key="${key}"]`;
const m = demo.menu;

// A menu opened at `at` (a point spec) or next to a parent row; `active` maps row titles to highlight windows.
function menu(id, items, {at, parent, open, active = {}}) {
  const attrs = {menu: open};
  if (at) attrs.at = at;
  if (parent) attrs.parent = parent;
  return menuHTML(items, {id, attrs, rowAttrs: (title) => (active[title] ? {win: `active@${active[title]}`} : {})});
}
const toast = (tpl, v, win) => ({text: fmt(tpl, v), attrs: {toast: win}});
const cursor = (path, clicks, enter) => `<span class="fake-cursor on" data-in="${enter} 0 0" data-path='${JSON.stringify(path)}' data-clicks="${clicks.join(',')}"></span>`;
const baseFiles = (attrs = {}) => demo.files.map((f) => ({...f, attrs: attrs[f.name]}));

function Copy({s, children}) {
  return <div className="copy">
    <p className="section-label" data-in="0.1"><span>// {s.num}</span>{s.label}</p>
    <h1 data-in="0.18"><span className="headline-en" lang="en">{s.headlineEn}</span><span className="headline-zh" lang="zh-CN">{s.headline}</span></h1>
    <p className="desc" data-in="0.3">{s.description}</p>
    {children}
  </div>;
}

// Set per render: vertical (9:16) films re-lay out the same shots.
let V = false;
const W = () => (V ? 1080 : 1920), H = () => (V ? 1920 : 1080);

function Stage({left, top, scale = 1.35, vert = {}, parts}) {
  if (V) ({left = 108, top = 760, scale = 1.6} = vert);
  const maxx = (W() - (V ? 24 : 48) - left) / scale, maxy = (H() - 40 - top) / scale;
  return <div className="stage" data-maxx={maxx} data-maxy={maxy} style={{left, top, transform: `scale(${scale})`}} {...html(parts.join(''))}/>;
}

// ---- Shot scripts. Times are seconds from the shot start; key actions land on 120 BPM beats.
const P = '.finder-content|168|175'; // blank space under the first row of files

function newShot() {
  const blank = menuFor(null);
  const types = submenu(blank, m.newFile);
  const untitled = `${demo.untitled}.md`, untitled2 = `${demo.untitled} 2.md`;
  const files = [...baseFiles({}),
    {name: untitled, kind: 'file', ext: 'md', attrs: {pop: 4, win: 'selected@4-6.5;renaming@4-5.6'}},
    {name: untitled2, kind: 'file', ext: 'md', attrs: {pop: 8.5, win: 'selected@8.5-11;renaming@8.5-11'}}];
  return [
    `<div class="finder-wrap" data-in="0.5 0 24 0.97">${finderHTML({files, toasts: [
      toast(demo.toast.created, {name: untitled}, '4-6.4'),
      toast(demo.toast.created, {name: untitled2}, '8.5-11'),
    ]})}</div>`,
    menu('n1', blank, {at: P, open: '2-3.95', active: {[m.newFile]: '2.7-3.95'}}),
    menu('n1s', types, {parent: `n1/${m.newFile}`, open: '2.85-3.95', active: {Markdown: '3.45-3.95'}}),
    menu('n2', blank, {at: P, open: '6.5-8.45', active: {[m.newFile]: '7.1-8.45'}}),
    menu('n2s', types, {parent: `n2/${m.newFile}`, open: '7.25-8.45', active: {Markdown: '7.7-8.45'}}),
    cursor([[0, 0, [640, 420]], [1, 1.9, P], [2.35, 2.7, `${row(`n1/${m.newFile}`)}|60|13`], [3.05, 3.45, `${row('n1s/Markdown')}|50|13`],
      [5.9, 6.4, P], [6.75, 7.1, `${row(`n2/${m.newFile}`)}|60|13`], [7.35, 7.7, `${row('n2s/Markdown')}|50|13`]],
    [2, 3.8, 6.5, 8.3], 0.9),
  ];
}

function sendShot() {
  const doc = '季度报告.docx', docs = demo.places[2];
  const items = menuFor(doc), blank = menuFor(null);
  const at = `${file(doc)}|52|40`;
  return [
    `<div class="finder-wrap" data-in="0.3 0 24 0.97">${finderHTML({
      files: baseFiles({[doc]: {win: 'selected@1.5-6.5'}}),
      sideAttrs: {[docs.path]: {win: 'flash@4-4.6,8.3-8.9'}},
      toasts: [toast(demo.toast.copiedTo, {name: doc, dest: docs.name}, '4-6.4'), toast(demo.toast.openedFolder, {dest: docs.name}, '8.3-11')],
    })}</div>`,
    `<span class="fly-ghost file-icon" data-fly="3.5" data-from='${file(doc)} .file-icon' data-to='[data-place="${docs.path}"]'><span class="doc" data-ext="docx" data-label="docx"></span></span>`,
    menu('s1', items, {at, open: '2-3.5', active: {[m.copyTo]: '2.7-3.5'}}),
    menu('s1s', submenu(items, m.copyTo), {parent: `s1/${m.copyTo}`, open: '2.85-3.5', active: {[docs.name]: '3.3-3.5'}}),
    menu('s2', blank, {at: P, open: '6.5-8.3', active: {[m.favorites]: '7.2-8.3'}}),
    menu('s2s', submenu(blank, m.favorites), {parent: `s2/${m.favorites}`, open: '7.35-8.3', active: {[docs.name]: '7.8-8.3'}}),
    cursor([[0, 0, [640, 420]], [0.8, 1.5, at], [2.3, 2.7, `${row(`s1/${m.copyTo}`)}|60|13`], [2.95, 3.3, `${row(`s1s/${docs.name}`)}|50|13`],
      [5.6, 6.3, P], [6.8, 7.2, `${row(`s2/${m.favorites}`)}|60|13`], [7.45, 7.8, `${row(`s2s/${docs.name}`)}|50|13`]],
    [1.5, 2, 3.45, 6.5, 8.2], 0.6),
  ];
}

function openShot() {
  const folder = '项目资料', note = '笔记.md';
  const fm = menuFor(folder), nm = menuFor(note);
  const [terminal, vscode] = demo.apps;
  const atF = `${file(folder)}|52|40`, atN = `${file(note)}|52|40`;
  return [
    `<div class="finder-wrap" data-in="0.3 0 24 0.97">${finderHTML({
      files: baseFiles({[folder]: {win: 'selected@1.3-4.8'}, [note]: {win: 'selected@4.8-9'}}),
      toasts: [toast(demo.toast.openedApp, {app: vscode.title, name: folder}, '4-6.4'),
        toast(demo.toast.openedApp, {app: terminal.title, name: demo.windowTitle}, '7-9')],
    })}</div>`,
    menu('o1', fm, {at: atF, open: '2-4.05', active: {[m.openInApp]: '2.7-4.05'}}),
    menu('o1s', submenu(fm, m.openInApp), {parent: `o1/${m.openInApp}`, open: '2.85-4.05', active: {[vscode.title]: '3.4-4.05'}}),
    menu('o2', nm, {at: atN, open: '5.2-6.9', active: {[m.openInApp]: '5.8-6.9'}}),
    menu('o2s', submenu(nm, m.openInApp), {parent: `o2/${m.openInApp}`, open: '5.95-6.9', active: {[terminal.title]: '6.4-6.9'}}),
    cursor([[0, 0, [640, 420]], [0.6, 1.3, atF], [2.3, 2.7, `${row(`o1/${m.openInApp}`)}|60|13`], [2.95, 3.4, `${row(`o1s/${vscode.title}`)}|60|13`],
      [4.3, 4.8, atN], [5.45, 5.8, `${row(`o2/${m.openInApp}`)}|60|13`], [6.05, 6.4, `${row(`o2s/${terminal.title}`)}|40|13`]],
    [1.3, 2, 4, 4.8, 5.2, 6.85], 0.4),
  ];
}

const highlight = ['转换图片…', '生成 macOS 图标集', '生成 iOS 图标集', '解散文件夹'];
function toolboxShot() {
  const img = '封面.png', folder = '项目资料';
  const im = menuFor(img), fm = menuFor(folder);
  const imTools = submenu(im, m.toolbox), fTools = submenu(fm, m.toolbox);
  const atI = `${file(img)}|40|40`, atF = `${file(folder)}|40|40`;
  const card = (name, kind, ext, tools, left) => `<div class="compare-card" style="left:${left}px" data-in="6.6 0 24">
      <p class="compare-head"><span class="ric ${kind === 'folder' ? 'folder' : 'image'}"></span>${escapeHTML(name)}</p>
      ${menuHTML(tools, {id: `c-${ext}`, extraClass: 'static', rowAttrs: (title) => (highlight.includes(title) ? {win: 'mark@7.2-99'} : {})})}
    </div>`;
  return [
    `<div class="finder-wrap" data-in="0.3 0 24 0.97" data-out="6.3">${finderHTML({
      files: baseFiles({[img]: {win: 'selected@1.2-3.8'}, [folder]: {win: 'selected@4.3-9'}}),
    })}</div>`,
    menu('t1', im, {at: atI, open: '1.5-3.6', active: {[m.toolbox]: '2.3-3.6'}}),
    menu('t1s', imTools, {parent: `t1/${m.toolbox}`, open: '2.45-3.6'}),
    menu('t2', fm, {at: atF, open: '4.5-6.3', active: {[m.toolbox]: '5.2-6.3'}}),
    menu('t2s', fTools, {parent: `t2/${m.toolbox}`, open: '5.35-6.3'}),
    card(img, 'image', 'png', imTools, V ? 0 : 20),
    card(folder, 'folder', 'dir', fTools, V ? 300 : 330),
    `<div data-out="6.3">${cursor([[0, 0, [640, 420]], [0.6, 1.2, atI], [1.8, 2.3, `${row(`t1/${m.toolbox}`)}|60|13`],
      [3.8, 4.3, atF], [4.75, 5.2, `${row(`t2/${m.toolbox}`)}|60|13`]], [1.2, 1.5, 4.3, 4.5], 0.4)}</div>`,
  ];
}

// ---- Shots
function Shot({s, children, cls = ''}) {
  return <section className={`shot shot-${s.type} ${cls}`} data-start={s.start} data-end={s.end} id={`shot-${s.id}`}>{children}</section>;
}
const img = (name) => `img/${name}`;

const scenes = {
  brand: (s) => <Shot s={s} cls="ink">
    <div className="grid-bg"/><div className="center-glow"/>
    <div className="brand-stack">
      <div className="brand-icon"><img data-pop="0.2" src={img('app-icon-512.png')} alt=""/><i className="ring" data-ring="0.55"/><i className="ring coral" data-ring="0.67"/></div>
      <p className="brand-word" data-in="0.9">RightKit<span className="dot">.</span></p>
      <h1 data-in="1.15"><span className="headline-en" lang="en">{s.headlineEn}</span><span className="headline-zh" lang="zh-CN">右键一下，<em>就办好了。</em></span></h1>
    </div>
  </Shot>,
  title: (s) => <Shot s={s} cls="ink">
    <div className="grid-bg"/>
    <div className="title-card">
      <h1 data-in="0.05"><span className="headline-en" lang="en">{s.headlineEn}</span><span className="headline-zh" lang="zh-CN">{s.headline}</span></h1>
      <p className="desc" data-in="0.2">{s.description}</p>
    </div>
    <div className="ticker-in" data-in="0.1 0 60"><div className="ticker"><div className="ticker-track" data-ticker="90">
      {[...s.ticker, ...s.ticker, ...s.ticker].map((w, i) => <React.Fragment key={i}><span>{w}</span><i/></React.Fragment>)}
    </div></div></div>
  </Shot>,
  new: (s) => <Shot s={s} cls="ink">
    <div className="grid-bg"/><div className="glow" style={{left: 1280, top: 150}}/>
    <div className="riko" data-in="0.35 40 0"><img data-float="7 8" src={img('hero-character-1120.webp')} alt=""/></div>
    <Copy s={s}>
      <ul className="types">{t.sections.new.types.map((ext, i) => <li key={ext} data-in={`${5 + i * 0.06} 0 16`}><span className="doc-ic" data-ext={ext}/>.{ext}</li>)}</ul>
      <p className="note" data-in="8.6">{s.note}</p>
    </Copy>
    <Stage left={790} top={430} vert={{left: 60, top: 1000, scale: 1.5}} parts={newShot()}/>
  </Shot>,
  send: (s) => <Shot s={s} cls="ink">
    <div className="grid-bg"/>
    <Copy s={s}><p className="note" data-in="5.6">{s.note}</p></Copy>
    <figure className="art" data-in="0.6"><img data-float="6.5 6" src={img('feature-copy-move-640.webp')} alt=""/></figure>
    <Stage left={800} top={300} parts={sendShot()}/>
  </Shot>,
  open: (s) => <Shot s={s} cls="ink">
    <div className="grid-bg"/>
    <Copy s={s}>
      <ul className="apps">{t.sections.open.apps.map((a, i) => <li key={a.icon} data-in={`${0.9 + i * 0.07} 0 16`}><img className="app-ic" src={img(`apps/${a.icon}-128.webp`)} alt=""/>{a.name}</li>)}</ul>
    </Copy>
    <figure className="art" data-in="0.6"><img data-float="6.5 6" src={img('feature-open-app-640.webp')} alt=""/></figure>
    <Stage left={800} top={300} parts={openShot()}/>
  </Shot>,
  toolbox: (s) => <Shot s={s} cls="ink">
    <div className="grid-bg"/>
    <Copy s={s}/>
    <figure className="art" data-in="0.6"><img data-float="6.5 6" src={img('feature-toolbox-640.webp')} alt=""/></figure>
    <Stage left={800} top={250} parts={toolboxShot()}/>
  </Shot>,
  safe: (s) => <Shot s={s} cls="paper">
    <Copy s={s}/>
    <ul className="cards safe-cards">{s.cards.map((c, i) => <li className="card" key={c.icon} data-in={`${0.6 + i * 0.07}`}>
      <svg className="card-ic" {...html(`<use href="#i-${c.icon}"/>`)}/><h3>{c.title}</h3></li>)}</ul>
  </Shot>,
  more: (s) => <Shot s={s} cls="ink">
    <div className="grid-bg"/>
    <Copy s={s}/>
    <ul className="intents">{intentTitles.map((x, i) => <li key={x} data-in={`${0.4 + i * 0.06} 0 16`}><svg className="ic" {...html('<use href="#i-shortcuts"/>')}/>{x}</li>)}</ul>
  </Shot>,
  end: (s) => <Shot s={s} cls="cta">
    <div className="cta-glow"/>
    <div className="end-copy">
      <div className="end-brand" data-in="0.1"><img src={img('app-icon-512.png')} alt=""/><span>RightKit<span className="dot">.</span></span></div>
      <h1 data-in="0.25"><span className="headline-en" lang="en">{s.headlineEn}</span><span className="headline-zh" lang="zh-CN">{t.cta.title1}<em>{t.cta.title2}</em></span></h1>
      <div className="actions" data-in="0.45"><span className="btn btn-primary btn-lg" {...html(`<svg class="ic"><use href="#i-download"/></svg>${escapeHTML(t.cta.download)}`)}/></div>
      <p className="fineprint" data-in="0.55">{s.description}</p>
    </div>
    <figure className="end-art" data-in="0.3 0 80"><img data-float="1.6 26" src={img('cta-character-960.webp')} alt=""/></figure>
  </Shot>,
};

// Section labels, safe cards and ticker words come from website/content.json.
const sectionOf = {new: 'new', send: 'send', open: 'open', toolbox: 'toolbox', safe: 'trust', more: 'more'};
const tool = (id) => t.toolbox.groups.flat().find((x) => x.id === id).title.replace(/…$/, '');
function enrich(s) {
  const sec = t.sections[sectionOf[s.id]];
  return {...s, ...(sec && {num: sec.num, label: sec.label}),
    cards: s.id === 'safe' ? sec.items.slice(0, 3) : undefined,
    ticker: s.id === 'title' ? [m.newFile, m.copyTo, m.moveTo, m.favorites, m.openInApp, ...['copyPath', 'convertImage', 'macIconset', 'hash', 'airdrop'].map(tool)] : undefined};
}

export function renderFilm(plan) {
  V = plan.height > plan.width;
  return renderToStaticMarkup(<main id="film" className={V ? 'vertical' : ''} style={{width: plan.width, height: plan.height}}>
    <div {...html(sprite)}/>
    {plan.shots.map((s) => <React.Fragment key={s.id}>{scenes[s.id](enrich(s))}</React.Fragment>)}
  </main>);
}
