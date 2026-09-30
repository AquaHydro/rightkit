// scenes_riko.js: the full 208 s timeline for "Under the Right Click". Line indices refer to LW (lyrics.js).
const shake = (c, t, t0, amp = 30, dur = .35) => { const u = (t - t0) / dur; if (u < 0 || u > 1) return; const k = amp * (1 - u) ** 2; c.translate(noise1(t * 60) * k, noise1(t * 60 + 50) * k); };
const wt = (li, re) => (words(li).find(w => re.test(w.w)) || words(li)[0]).t;
const wT = li => words(li).map(w => w.t);
// clip frame at clip-local time (for reusing a shot somewhere else in the song)
const clip = (S, lt) => shotFrame(S, lt);
const bg = (c, col, t) => fill(c, col);

// ---- Riko's vocabulary: the cursor and the context menu (the hair clip, blown up)
function cursor(c, x, y, s, o = {}) {
  c.save(); c.translate(x, y); c.scale(s / 100, s / 100); c.rotate(o.rot || 0);
  c.beginPath(); c.moveTo(0, 0); c.lineTo(0, 78); c.lineTo(20, 60); c.lineTo(34, 92); c.lineTo(48, 86); c.lineTo(34, 55); c.lineTo(60, 55); c.closePath();
  c.lineJoin = 'round'; c.lineWidth = 12; c.strokeStyle = o.stroke || INK.paper; c.stroke(); c.fillStyle = o.col || INK.ink; c.fill(); c.restore();
}
function ctxMenu(c, x, y, s, items, hi = -1, u = 1, o = {}) {
  if (u <= 0) return; const rw = 520, rh = 78, pad = 18, h = pad * 2 + items.length * rh;
  c.save(); c.translate(x, y); c.scale(s, s * E.outB(clamp(u * 1.2))); c.globalAlpha = o.a ?? 1;
  c.fillStyle = o.shadow || INK.blue; c.beginPath(); c.roundRect(14, 14, rw, h, 26); c.fill();
  c.fillStyle = o.bg || INK.paper; c.strokeStyle = INK.ink; c.lineWidth = 5; c.beginPath(); c.roundRect(0, 0, rw, h, 26); c.fill(); c.stroke();
  items.forEach(([label, col], i) => {
    const iy = pad + i * rh; if (u < i / items.length) return;
    if (i === hi) { c.fillStyle = INK.coral; c.beginPath(); c.roundRect(12, iy + 4, rw - 24, rh - 8, 16); c.fill(); }
    c.fillStyle = i === hi ? INK.paper : col; c.beginPath(); c.roundRect(40, iy + rh / 2 - 14, 28, 28, 7); c.fill();
    c.fillStyle = i === hi ? INK.paper : INK.ink; c.font = F.arch(40); c.textBaseline = 'middle'; c.textAlign = 'left'; c.fillText(label, 96, iy + rh / 2 + 2);
  });
  c.restore();
}
const MENU = [['New File', INK.make], ['Copy Path', INK.copy], ['Move to…', INK.send], ['Open With', INK.nav]];
function evaText(c, s, x, y, size, col, align = 'left') { c.save(); c.font = F.mincho(size); c.fillStyle = col; c.textAlign = align; c.textBaseline = 'alphabetic'; c.translate(x, y); c.scale(.82, 1); c.fillText(s, 0, 0); c.restore(); }
function whiteIn(c, t, t0, d = .12) { if (t < t0 || t > t0 + d) return; c.save(); c.fillStyle = INK.paper; c.globalAlpha = 1 - (t - t0) / d; c.fillRect(0, 0, W, H); c.restore(); }
function scrimBottom(c, a = .9) { const g = c.createLinearGradient(0, H, 0, H * .45); g.addColorStop(0, `rgba(18,32,63,${a})`); g.addColorStop(1, 'rgba(18,32,63,0)'); c.fillStyle = g; c.fillRect(0, 0, W, H); }

// ---- HUD: layer name + an entropy meter that rises in the verses and gets knocked down by every click
const ENT = [[0, 12], [2.3, 97.3], [40.53, 81], [46.54, 64], [46.96, 47], [47.39, 30], [65, 58], [85, 88], [96.7, 99.9], [99.81, 80], [106, 55], [110, 36], [118, 20],
  [133.5, 44], [158.47, 70], [161.63, 88], [164.43, 99.9], [167.55, 60], [174, 30], [178.4, 12], [185, 4], [193.3, 0]];
const entropy = t => { let v = ENT[0][1]; for (let i = 1; i < ENT.length; i++) if (t >= ENT[i][0]) v = lerp(ENT[i - 1][1], ENT[i][1], E.outX(clamp((t - ENT[i][0]) / .6))); return v; };
function hud(c, t, o = {}) {
  const col = o.col || INK.paper; c.save(); c.fillStyle = col; c.font = F.mono(24); c.textBaseline = 'top'; c.textAlign = 'left';
  c.fillText('ARCHIVE CITY', 56, 48); c.font = F.monoL(20); c.globalAlpha = .75; c.fillText(o.layer || 'LAYER 07 · 第七層 · OUT OF ORDER', 56, 82);
  const v = entropy(t), x = W - 56; c.globalAlpha = 1; c.textAlign = 'right'; c.font = F.mono(24); c.fillText(v <= 0.05 ? 'ENTROPY 0.0% · ALL ARCHIVED' : `ENTROPY ${v.toFixed(1)}%`, x, 48);
  c.globalAlpha = .35; c.fillRect(x - 260, 88, 260, 8); c.globalAlpha = 1; c.fillStyle = v > 60 ? INK.rose : INK.coral; c.fillRect(x - 260, 88, 260 * v / 100, 8);
  c.restore();
}
// word-by-word slam of a whole line, centred. cols cycles per word
function slamLine(c, t, li, y, size, cols, o = {}) {
  const ws = words(li).map(w => ({ ...w, s: (o.upper ?? true) ? w.w.toUpperCase() : w.w }));
  const measure = sz => { c.font = (o.font || F.anton)(sz); const wd = ws.map(w => c.measureText(w.s).width); return [wd, wd.reduce((a, b) => a + b, 0) + sz * .25 * (ws.length - 1)]; };
  let [wd, tot] = measure(size); const maxW = W - 240; if (tot > maxW) { size *= maxW / tot; [wd, tot] = measure(size); }
  const sp = size * .25; let x = W / 2 - tot / 2;
  ws.forEach((w, i) => { slam(c, w.s, x + wd[i] / 2, y, size, t, w.t, { font: o.font || F.anton, col: cols[i % cols.length], shadow: o.shadow || INK.ink, from: 1.7, rot: (hash(i, li) - .5) * .08 }); x += wd[i] + sp; });
}

// =====================================================================================  INTRO
async function sc_boot(c, t) {
  fill(c, '#0E0F13'); c.save(); c.fillStyle = INK.paper; c.font = F.monoL(30); c.textAlign = 'left'; c.textBaseline = 'top';
  const L = ['rightkit://archive-city/layer-07', 'mounting 1,048,576 folders …', 'checking names … FAILED', 'entropy rising'];
  L.forEach((s, i) => { const n = Math.floor(clamp((t - .15 - i * .5) * 40, 0, s.length)); if (n > 0) c.fillText(s.slice(0, n), 140, 380 + i * 52); });
  if (Math.floor(t * 4) % 2) cursor(c, W / 2 - 20, H / 2 + 200, 70);
  c.restore(); hud(c, t); return { grain: .07 };
}
async function sc_alert(c, t) {
  warnPanel(c, t, { text: 'ENTROPY ALERT', col: INK.rose, bg: '#0E0F13', sub: ['LAYER: 07', 'INDEX: CORRUPTED', 'NAMES LOST: 1,048,576', `ENTROPY: ${entropy(t).toFixed(1)}%`] });
  if (t > wt(0, /alert/)) stamp(c, 'OUT OF ORDER', W - 420, H - 170, t, wt(0, /alert/) + .3, { col: INK.coral, size: 70, rot: -.08 });
  return { mis: 3.5 };
}
async function sc_city(c, t) {
  const lt = t - 4.55; fill(c, INK.navy);
  await celDraw(c, 'img/set_rooftop.jpg', { pal: 'night', t, cam: { x: .5, y: .45 - lt * .01, z: 1.25 - lt * .05 }, misCol: INK.blue });
  c.save(); c.fillStyle = 'rgba(18,32,63,.45)'; c.fillRect(0, 0, W, H); c.restore();
  evaText(c, '第七層', 130, 420, 230, INK.paper); evaText(c, '失序', 130, 660, 230, INK.coral);
  const ws = words(1); c.font = F.mincho(58); c.fillStyle = INK.paper; c.textAlign = 'right';
  c.fillText(ws.filter(w => t >= w.t).map(w => w.w).join(' ').toUpperCase(), W - 130, H - 150);
  hud(c, t); return { mis: 2 };
}
async function sc_A(c, t) {
  const tc = 10.18;
  if (t >= tc) { evaCard(c, [{ text: 'UNDER THE', x: 150, y: 400, size: 210, font: F.anton, sx: 1 }, { text: 'RIGHT CLICK', x: 150, y: 640, size: 250, font: F.anton, sx: 1, col: INK.coral },
    { text: '右クリックの向こう', x: 160, y: 820, size: 96 }, { text: 'EPISODE:07', x: W - 150, y: H - 120, size: 50, align: 'right' }], { bg: '#0E0F13' }); whiteIn(c, t, tc); return { grain: .06 }; }
  fill(c, INK.navy); await celDraw(c, sdFrame('A', t), { pal: 'night', t, cam: { x: .5, y: .45, z: 1.06 }, misCol: INK.blue, shade: .24 });
  hud(c, t); return {};
}
// =====================================================================================  VERSE 1
async function sc_B(c, t) {
  fill(c, INK.navy); await celDraw(c, sdFrame('B', t), { pal: 'night', t, cam: { x: .5, y: .5, z: 1.05 }, misCol: INK.blue, shade: .26 });
  c.save(); c.globalAlpha = clamp((t - 11.2) / .3); vjp(c, '真夜中のアーカイブ・シティ', 150, 150, 70, INK.paper, clamp((t - 11.2) / 3)); c.restore();
  if (t > wt(2, /崩/)) vjp(c, '崩れてく塔', 260, 150, 70, INK.coral, clamp((t - wt(2, /崩/)) / 1.2));
  hud(c, t); return {};
}
async function sc_C(c, t) {
  fill(c, INK.navy); await celDraw(c, sdFrame('C', t), { pal: 'face', t, cam: { x: .5, y: .45, z: 1.06 }, misCol: INK.blue, shade: .2, expo: .98, sat: 1.05 });
  scrimBottom(c, .7); sub(c, t, 3, { en: 'Nameless files dance down like snow' }); hud(c, t); return {};
}
async function sc_path(c, t) {
  fill(c, INK.paper); const segs = ['Archive City', 'Layer 07', 'Drafts', '2026', '▇▇▇▇', '?'], y = 470; const br = wt(4, /誰/);
  c.save(); c.font = F.arch(58); c.textBaseline = 'middle';
  const span = segs.reduce((a, s) => a + c.measureText(s).width + 114, -44), sc = Math.min(1, (W - 240) / span);
  c.translate(W / 2, y); c.scale(sc, sc); c.translate(-W / 2, -y); let x = W / 2 - span / 2;
  segs.forEach((s, i) => { const w = c.measureText(s).width + 70, appear = 22.18 + i * BEAT * .75; if (t < appear) return;
    const u = clamp((t - br - i * .06) / .9), dx = u * (i - 2.5) * 120, dy = E.inQ(u) * (300 + hash(i) * 600), rot = u * (hash(i, 3) - .5) * 1.4;
    c.save(); c.translate(x + w / 2 + dx, y + dy); c.rotate(rot);
    c.fillStyle = i === segs.length - 1 ? INK.rose : INK.cream; c.strokeStyle = INK.ink; c.lineWidth = 5; c.beginPath(); c.roundRect(-w / 2, -50, w, 100, 18); c.fill(); c.stroke();
    c.fillStyle = INK.ink; c.textAlign = 'center'; c.fillText(s, 0, 4); c.restore(); x += w + 44;
    if (i < segs.length - 1 && u === 0) { c.fillStyle = INK.coral; c.fillText('›', x - 34, y); } });
  c.restore();
  halftone(c, 0, 700, W, 380, 22, (px, py) => .12 + .1 * Math.sin(px * .01 + t), INK.blue);
  slamLine(c, t, 4, 850, 110, [INK.ink, INK.rose], { upper: false, font: F.jp, shadow: INK.coral });
  hud(c, t, { col: INK.ink }); return { mis: 2 };
}
async function sc_lost(c, t) {
  const lt = t - 25.85; fill(c, INK.navy);
  await celDraw(c, 'img/set_stacks.jpg', { pal: 'night', t, cam: { x: .5, y: .35 + lt * .03, z: 1.3 }, misCol: INK.blue });
  // one untitled file card tumbling down
  c.save(); c.translate(W * .62 + Math.sin(lt * 1.7) * 90, 120 + lt * 170); c.rotate(Math.sin(lt * 2.3) * .5); c.fillStyle = INK.paper; c.strokeStyle = INK.ink; c.lineWidth = 5;
  c.beginPath(); c.moveTo(-90, -120); c.lineTo(50, -120); c.lineTo(90, -80); c.lineTo(90, 120); c.lineTo(-90, 120); c.closePath(); c.fill(); c.stroke();
  c.fillStyle = INK.ink; c.font = F.mono(24); c.textAlign = 'center'; c.fillText('untitled', 0, 20); c.restore();
  scrimBottom(c, .8); sub(c, t, 5, { en: 'Lost even the place to go home' }); hud(c, t); return {};
}
// =====================================================================================  PRE-CHORUS 1
async function sc_finger(c, t) {
  const lt = t - 29.48; fill(c, INK.navy);
  await celDraw(c, clip('S1', 3.6 + lt * .28), { pal: 'face', t, cam: { x: .36, y: .5, z: 1.5 + lt * .06 }, misCol: INK.blue, shade: .2, expo: .98 });
  const g = .6 + .4 * Math.sin(t * 9); c.save(); c.globalCompositeOperation = 'screen'; spark(c, W * .4, H * .28, 90 + 40 * g, { n: 4, col: INK.paper, inner: .1, rot: t }); c.restore();
  cursor(c, W * .4 + 10, H * .28 + 10, 90);
  side(c, t, 6, { x: 1060, y: 700, w: 760, size: 92, font: F.jp, upper: false, col: INK.paper, shadow: INK.rose, jp: false });
  hud(c, t); return {};
}
async function sc_E(c, t) {
  fill(c, INK.navy); await celDraw(c, sdFrame('E', t), { pal: 'face', t, cam: { x: .5, y: .45, z: 1.08 }, misCol: INK.blue, shade: .2, expo: .98, sat: 1.05 });
  // the three lines of the hair clip, drawn big on the beat
  const t0 = 33.83; for (let i = 0; i < 3; i++) { const u = E.outC(clamp((t - t0 - i * BEAT) / .3)); c.fillStyle = INK.coral; c.beginPath(); c.roundRect(120, 330 + i * 110, 380 * u, 56, 28); c.fill(); }
  c.save(); c.globalAlpha = clamp((t - 35.2) / .3); vjp(c, 'それだけを信じて', W - 150, 150, 80, INK.paper, clamp((t - 35.3) / 2.5)); c.restore();
  hud(c, t); return {};
}
// =====================================================================================  CHORUS (shared by chorus 1 and 2)
function sc_countAt(li) {
  return async (c, t) => {
    const bs = wT(li), n = bs.filter(b => t >= b).length;
    if (n === 0) { fill(c, INK.ink); return { grain: .06 }; }
    const bgc = [INK.ink, INK.paper, INK.coral][n - 1], fg = n === 2 ? INK.ink : INK.paper;
    fill(c, bgc); c.save(); shake(c, t, bs[n - 1], 26, .25);
    slam(c, String(4 - n), W / 2, H / 2 + 20, 760, t, bs[n - 1], { font: F.anton, col: fg, shadow: n === 3 ? INK.rose : INK.blue, from: 1.6 });
    c.restore(); evaText(c, '第七層', 120, 250, 150, fg); evaText(c, '失序', 120, 400, 150, fg);
    c.font = F.mincho(46); c.fillStyle = fg; c.textAlign = 'right'; c.fillText('LAYER SEVEN, OUT OF ORDER', W - 120, H - 120);
    return { grain: .06, mis: 2.2 };
  };
}
// RIGHT CLICK! close-up. base = song time of "Right" for this chorus; the S1 clip is aligned so its 1.19 s sits on "Right"
function sc_clickAt(li, cam0 = .5) {
  return async (c, t) => {
    const r = words(li)[0].t, lt = t - r, k = wt(li, /click/);
    fill(c, INK.navy); c.save(); shake(c, t, r, 34, .4); shake(c, t, k, 22, .3);
    await celDraw(c, clip('S1', 1.19 + lt), { pal: 'face', t, cam: { x: cam0, y: .42, z: 1.12 + lt * .05 }, misCol: INK.blue, shade: .2, expo: .98, sat: 1.05 });
    c.restore(); scrimBottom(c);
    if (t < k + .5) {
      slam(c, 'RIGHT', W * .5 - 410, H * .72, 300, t, r, { font: F.anton, col: INK.paper, shadow: INK.rose, rot: -.04 });
      slam(c, 'CLICK!', W * .5 + 390, H * .72, 300, t, k, { font: F.anton, col: INK.coral, shadow: INK.ink, rot: .05 });
      if (t > k) { const u = (t - k) / .35; if (u < 1) { c.save(); c.globalAlpha = 1 - u; c.strokeStyle = INK.paper; c.lineWidth = 16 * (1 - u); c.beginPath(); c.arc(W * .5 + 390, H * .72, 200 + u * 700, 0, TAU); c.stroke(); c.restore(); } }
    } else { const j = words(li).at(-1); c.save(); c.globalAlpha = clamp((t - j.t) / .2); vjp(c, j.w, W - 150, 150, 84, INK.paper, clamp((t - j.t) / 2.2)); c.restore(); }
    const pk = r + 2.86; if (t > pk) { const u = clamp((t - pk) / .35); ctxMenu(c, 90, H * .42, .95, MENU, -1, u); cursor(c, 80, H * .42 - 20, 90); }
    whiteIn(c, t, r); hud(c, t); return { mis: t < r + .4 ? 3 : 1.5 };
  };
}
// pull back with blooming menus + NEW FILE / COPY / MOVE. liA = 重なる line, liB = New file line, S2 clip 0.06 s sits on liA
const BLOOM = [[.12, .24, .5], [.76, .22, .55], [.03, .56, .44], [.84, .54, .48], [.24, .66, .38], [.68, .7, .4]];
function sc_bloomAt(liA, liB) {
  return async (c, t) => {
    const a = words(liA)[0].t; fill(c, INK.navy);
    await celDraw(c, clip('S2', .06 + t - a), { pal: 'night', t, cam: { x: .5, y: .5, z: 1.04 }, misCol: INK.blue, shade: .28, expo: 1.1 });
    const nw = words(liB)[0].t, fl = wt(liB, /file/), cp = wt(liB, /copy/), mv = wt(liB, /move/), jp = words(liB).at(-1).t;
    const b0 = Math.ceil(beatOf(a)), nb = Math.floor(beatOf(t)) - b0 + 1;
    BLOOM.forEach(([x, y, s], i) => { if (i >= nb) return; const u = clamp((t - beatT(b0 + i)) / .25);
      ctxMenu(c, x * W, y * H + Math.sin(t * 1.3 + i) * 10, s, MENU, Math.floor(t * 4 + i) % 4, u * (1 - clamp((t - nw + .2) / .3)), { a: .92, shadow: i % 2 ? INK.rose : INK.blue }); });
    if (t < nw) sub(c, t, liA, { en: 'Stacked menus bloom like spells in the night' });
    else if (t < jp) {
      const hi = t < fl ? -1 : t < cp ? 0 : t < mv ? 1 : 2; c.save(); shake(c, t, [fl, cp, mv][Math.max(0, hi)], 18, .25);
      ctxMenu(c, 170, 300, 1.25, MENU.slice(0, 3), hi, clamp((t - nw) / .2), { shadow: INK.rose }); c.restore();
      const lab = hi < 0 ? 'NEW' : ['NEW FILE', 'COPY', 'MOVE'][hi], at = hi < 0 ? nw : [fl, cp, mv][hi];
      slam(c, lab, W * .72, H * .8, 250, t, at, { font: F.anton, col: [INK.paper, INK.paper, INK.coral][Math.max(0, hi)], shadow: [INK.make, INK.copy, INK.send][Math.max(0, hi)], from: 1.8 });
    } else { c.save(); c.globalAlpha = clamp((t - jp) / .2); vjp(c, words(liB).at(-1).w, W - 150, 150, 92, INK.paper, clamp((t - jp) / 2.6)); c.restore(); }
    hud(c, t); return {};
  };
}
function sc_rcrnAt(li, bgs = [INK.paper, INK.ink, INK.coral, INK.blue]) {
  return async (c, t) => {
    const ws = wT(li), n = Math.max(0, ws.filter(b => t >= b).length - 1); fill(c, bgs[n % bgs.length]);
    const fg = [INK.ink, INK.paper, INK.paper, INK.paper][n % 4]; c.save(); shake(c, t, ws[n], 30, .25);
    halftone(c, 0, 0, W, H, 26, (x, y) => .08 + .12 * ((x + y + t * 400) % 600) / 600, fg);
    slamLine(c, t, li, H / 2 + 20, 250, [fg, n % 2 ? INK.rose : INK.coral], { shadow: n === 0 ? INK.rose : INK.ink });
    c.restore(); return { mis: 3 };
  };
}
// =====================================================================================  CHORUS 1 tail
async function sc_F(c, t) {
  fill(c, INK.navy); c.save(); shake(c, t, 51.06, 20, .6);
  await celDraw(c, sdFrame('FG', t), { pal: 'night', t, cam: { x: .5, y: .5, z: 1.05 }, misCol: INK.blue, shade: .26 }); c.restore();
  scrimBottom(c, .75);
  if (t < wt(12, /put/)) sub(c, t, 12, { en: 'Even if the entropy wave runs high' });
  else slamLine(c, t, 12, H * .78, 190, [INK.paper, INK.paper, INK.coral, INK.coral].slice(0), { shadow: INK.rose }), 0;
  hud(c, t); return {};
}
function drawPutRight(c, t, li) { const ws = words(li).filter(w => /put|it|all|right/i.test(w.w)); }
async function sc_G(c, t) {
  fill(c, INK.navy); await celDraw(c, sdFrame('FG', t), { pal: 'night', t, cam: { x: .5, y: .5, z: 1.04 }, misCol: INK.blue, shade: .26 });
  const im = wt(14, /I'm/); scrimBottom(c, .6);
  if (t < im) { c.save(); c.globalAlpha = clamp((t - 56.89) / .2); vjp(c, '混沌の果てで', W - 150, 150, 92, INK.paper, clamp((t - 56.89) / 1.8)); c.restore(); }
  else { c.save(); shake(c, t, im, 20, .4); slam(c, "I'M", W * .3, H * .76, 230, t, im, { font: F.anton, col: INK.paper, shadow: INK.rose }); slam(c, 'HERE', W * .62, H * .76, 300, t, wt(14, /here/), { font: F.anton, col: INK.coral, shadow: INK.ink }); c.restore();
    if (t > 62.9) speedLines(c, W / 2, H / 2, t, { n: 60, a: .35 * clamp((t - 62.9) / 1), col: INK.paper, r0: 520 }); }
  hud(c, t); return {};
}
// =====================================================================================  VERSE 2 (iron rain, almost mono)
function rain(c, t, o = {}) { const r = rng(Math.floor(t * 12) + 3); c.save(); c.strokeStyle = o.col || INK.mist; c.globalAlpha = o.a ?? .5; c.lineWidth = 2;
  for (let i = 0; i < (o.n || 160); i++) { const x = r() * W, y = r() * H, l = 40 + r() * 80; c.beginPath(); c.moveTo(x, y); c.lineTo(x - l * .18, y + l); c.stroke(); } c.restore(); }
async function sc_H(c, t) {
  fill(c, INK.ink); await celDraw(c, sdFrame('H', t), { pal: 'rain', t, cam: { x: .5, y: .5, z: 1.05 }, misCol: '#5A6FA8', shade: .3, sat: .45 });
  rain(c, t); scrimBottom(c, .6); sub(c, t, 15, { en: 'Iron rain soaks every line' }); hud(c, t, { layer: 'LAYER 07 · 鉄色の雨' }); return { grain: .05 };
}
async function sc_draft(c, t) {
  const lt = t - 70.45; fill(c, INK.ink);
  await celDraw(c, 'img/K_draft.jpg', { pal: 'rain', t, cam: { x: .45, y: .55, z: 1.2 + lt * .03 }, misCol: '#5A6FA8', shade: .3, sat: .8 });
  const g = .5 + .5 * Math.sin(t * 5); c.save(); c.globalCompositeOperation = 'screen'; c.globalAlpha = .35 + .25 * g;
  const rg = c.createRadialGradient(W * .5, H * .66, 10, W * .5, H * .66, 420); rg.addColorStop(0, INK.coral); rg.addColorStop(1, 'rgba(255,143,108,0)'); c.fillStyle = rg; c.fillRect(0, 0, W, H); c.restore();
  rain(c, t, { a: .35 }); side(c, t, 16, { x: 110, y: 200, w: 900, size: 92, font: F.jp, upper: false, col: INK.paper, shadow: INK.coral, jp: false });
  hud(c, t, { layer: 'LAYER 07 · 鉄色の雨' }); return {};
}
async function sc_I(c, t) {
  fill(c, INK.ink); await celDraw(c, sdFrame('IJ', t), { pal: 'rain', t, cam: { x: .5, y: .45, z: 1.06 }, misCol: '#5A6FA8', shade: .26, sat: .65 });
  rain(c, t, { a: .3 }); scrimBottom(c, .6); sub(c, t, 17, { en: 'The little mouse raised its coral ear' }); hud(c, t, { layer: 'LAYER 07 · 鉄色の雨' }); return {};
}
async function sc_J(c, t) {
  fill(c, INK.ink); await celDraw(c, sdFrame('IJ', t), { pal: 'rain', t, cam: { x: .5, y: .5, z: 1.05 }, misCol: '#5A6FA8', shade: .3, sat: .5 });
  rain(c, t, { a: .45 }); const g = .6 + .4 * Math.sin(t * 7); c.save(); c.globalCompositeOperation = 'screen'; spark(c, W * .5, H * .44, 40 + 30 * g, { n: 4, col: INK.coral, inner: .2 }); c.restore();
  c.save(); c.globalAlpha = clamp((t - 81.02) / .2); vjp(c, '帰り道のサイン', W - 150, 150, 80, INK.coral, clamp((t - wt(18, /帰/)) / 1.8)); c.restore();
  hud(c, t, { layer: 'LAYER 07 · 鉄色の雨' }); return {};
}
async function sc_signal(c, t) {
  const lt = t - 85.14; fill(c, INK.ink);
  await celDraw(c, 'img/set_street.jpg', { pal: 'rain', t, cam: { x: .5, y: .5, z: 1.1 + lt * .02 }, misCol: '#5A6FA8', shade: .3, sat: .3 });
  rain(c, t, { a: .4 });
  c.save(); c.strokeStyle = INK.coral; c.lineWidth = 4; for (let i = 0; i < 4; i++) { const u = ((t * .8 + i / 4) % 1); c.globalAlpha = 1 - u; c.beginPath(); c.arc(W / 2, H * .5, 40 + u * 700, 0, TAU); c.stroke(); } c.restore();
  c.save(); c.fillStyle = INK.paper; c.font = F.mono(40); c.textAlign = 'center'; if (Math.floor(t * 3) % 2) c.fillText('WAITING FOR SIGNAL', W / 2, H * .5 + 12); c.restore();
  kara(c, t, 19, { box: [120, 720, W - 240, 220], max: 120, font: F.jp, upper: false, col: INK.paper, accent: INK.coral, shadow: INK.ink, align: 'center' });
  hud(c, t, { layer: 'LAYER 07 · MONOCHROME' }); return {};
}
async function sc_K(c, t) {
  fill(c, INK.navy); c.save(); shake(c, t, 90.59, 24, .5);
  await celDraw(c, sdFrame('K', t), { pal: 'night', t, cam: { x: .5, y: .5, z: 1.06 }, misCol: INK.blue, shade: .26 }); c.restore();
  speedLines(c, W / 2, H / 2, t, { n: 50, a: .25, col: INK.paper, r0: 600 });
  scrimBottom(c, .7); sub(c, t, 20, { en: 'No folder is too deep, I will find you' }); hud(c, t); return {};
}
// =====================================================================================  CHORUS 2 tail
async function sc_wave2(c, t) {
  const lt = t - 110.35, rt = wt(25, /right/); fill(c, INK.navy); c.save(); shake(c, t, rt, 40, .5);
  await celDraw(c, clip('FG', .3 + lt), { pal: 'night', t, cam: { x: .5, y: .45, z: 1.18 }, misCol: INK.blue, shade: .26 }); c.restore();
  if (t > rt) { const u = E.outX(clamp((t - rt) / .4)); c.save(); c.fillStyle = INK.paper; c.beginPath(); c.moveTo(W / 2 - 30 - u * 200, 0); c.lineTo(W / 2 + 30 + u * 200, 0); c.lineTo(W / 2 + 10 + u * 90, H); c.lineTo(W / 2 - 10 - u * 90, H); c.fill(); c.restore(); }
  scrimBottom(c, .75);
  if (t < wt(25, /put/)) sub(c, t, 25, { en: 'Even if the entropy wave runs high' }); else slamLine(c, t, 25, H * .78, 190, [INK.paper, INK.paper, INK.coral, INK.coral], { shadow: INK.rose });
  hud(c, t); return {};
}
async function sc_O(c, t) {
  fill(c, INK.navy); await celDraw(c, sdFrame('O', t), { pal: 'night', t, cam: { x: .5, y: .5, z: 1.04 }, misCol: INK.blue, shade: .26 });
  const im = wt(27, /I'm/);
  if (t < im) { c.save(); c.globalAlpha = clamp((t - 116.09) / .2); vjp(c, '混沌の果てで', W - 150, 150, 92, INK.paper, clamp((t - 116.09) / 1.8)); c.restore(); }
  else if (t < im + 3.5) { c.save(); shake(c, t, im, 20, .4); slam(c, "I'M", W * .3, H * .78, 230, t, im, { font: F.anton, col: INK.paper, shadow: INK.rose }); slam(c, 'HERE', W * .62, H * .78, 300, t, wt(27, /here/), { font: F.anton, col: INK.coral, shadow: INK.ink }); c.restore(); }
  else { const b = Math.floor(beatOf(t)); if (b % 4 === 0) { c.save(); c.globalAlpha = pulse(t, 5) * .6; c.fillStyle = INK.coral; c.fillRect(0, 0, W, H); c.restore(); } }
  hud(c, t); return {};
}
// every beat a different shot, inks swap, speed lines; last bar white-out into the bridge
const MONT = [['S1', 3.8, 'face'], ['B', 2.0, 'night'], ['FG', 1.5, 'night'], ['H', 2.5, 'rain'], ['IJ', 1.0, 'rain'], ['K', 3.0, 'night'], ['S2', 5.0, 'night'], ['E', 4.0, 'face'], ['O', 12.0, 'night'], ['C', 2.0, 'face'], ['A', 3.2, 'night'], ['IJ', 7.0, 'rain']];
async function sc_montage(c, t) {
  const b = Math.floor(beatOf(t)), k = ((b % MONT.length) + MONT.length) % MONT.length, [S, lt, pal] = MONT[k], u = beatOf(t) - b;
  fill(c, INK.ink); c.save(); c.translate(W / 2, H / 2); c.scale(1.08 + u * .06, 1.08 + u * .06); c.translate(-W / 2, -H / 2);
  await celDraw(c, clip(S, lt + u * BEAT), { pal, t, cam: { x: .5, y: .45, z: 1.15 }, misCol: b % 2 ? INK.rose : INK.blue, shade: .28 }); c.restore();
  if (b % 2) { c.save(); c.globalCompositeOperation = 'multiply'; c.fillStyle = [INK.coral, INK.blue, INK.rose][b % 3]; c.globalAlpha = .45; c.fillRect(0, 0, W, H); c.restore(); }
  speedLines(c, W / 2, H / 2, t, { n: 70, a: .4, col: INK.paper, r0: 500 });
  const cards = ['第七層', '再索引', '復元', '右クリック', 'RE:INDEX', 'RESTORE', 'LAYER 07', 'ARCHIVE'];
  if (b % 4 === 3) evaCard(c, [{ text: cards[(b >> 2) % cards.length], x: 150, y: H / 2 + 110, size: 300 }], { bg: b % 8 === 3 ? INK.ink : INK.coral, fg: INK.paper });
  const wo = clamp((t - 132.2) / 1.2); if (wo > 0) { c.save(); c.globalAlpha = wo; c.fillStyle = INK.paper; c.fillRect(0, 0, W, H); c.restore(); }
  hud(c, t); return { mis: 3, flash: 0 };
}
// =====================================================================================  BRIDGE
async function sc_P(c, t) {
  fill(c, INK.paper); await celDraw(c, sdFrame('P', t), { pal: 'blank', t, cam: { x: .5, y: .5, z: 1.03 }, misCol: INK.mist, shade: .16, line: .9 });
  const li = [28, 29, 30].find(i => t >= LY[i][0] - .1 && t < LY[i][1] + .4) ?? -1;
  if (li >= 0) sub(c, t, li, { col: INK.ink, stroke: INK.paper, en: ['If someday I am forgotten too', 'Just click the empty space, gently', 'A small line of light will tell you'][li - 28] });
  const fi = clamp((133.52 - t) / .6 + 1); if (t < 134.2) { c.save(); c.globalAlpha = 1 - clamp((t - 133.52) / .6); c.fillStyle = INK.paper; c.fillRect(0, 0, W, H); c.restore(); }
  hud(c, t, { col: INK.ink, layer: 'LAYER 00 · 空白' }); return { vig: .2, grain: .025 };
}
async function sc_archived(c, t) {
  fill(c, INK.paper); halftone(c, 0, 0, W, H, 30, (x, y) => .05 + .05 * Math.sin((x + y) * .004 + t * .6), INK.mist);
  const ws = words(31), u = E.outB(clamp((t - 149.72) / .4)), x = W / 2 - 520, y = H / 2 - 150;
  c.save(); c.translate(W / 2, H / 2); c.scale(u, u); c.translate(-W / 2, -H / 2);
  c.fillStyle = INK.blue; c.beginPath(); c.roundRect(x + 16, y + 16, 1040, 300, 36); c.fill();
  c.fillStyle = INK.cream; c.strokeStyle = INK.ink; c.lineWidth = 6; c.beginPath(); c.roundRect(x, y, 1040, 300, 36); c.fill(); c.stroke();
  c.fillStyle = INK.make; c.beginPath(); c.arc(x + 130, y + 150, 64, 0, TAU); c.fill();
  c.strokeStyle = INK.paper; c.lineWidth = 16; c.lineCap = 'round'; c.beginPath(); c.moveTo(x + 98, y + 152); c.lineTo(x + 124, y + 180); c.lineTo(x + 166, y + 120); c.stroke();
  c.fillStyle = INK.ink; c.textAlign = 'left'; c.textBaseline = 'middle'; c.font = F.arch(76); if (t > ws[0].t) c.fillText('Archived.', x + 240, y + 110);
  c.font = F.mincho(58); const s2 = ws.slice(1).filter(w => t >= w.t).map(w => w.w).join(' ').replace(/,$/, ''); c.fillStyle = INK.coral; c.fillText(s2, x + 240, y + 200);
  c.restore();
  const fo = clamp((t - 157.3) / .8); if (fo > 0) { c.save(); c.globalAlpha = fo; c.fillStyle = INK.ink; c.fillRect(0, 0, W, H); c.restore(); }
  hud(c, t, { col: INK.ink, layer: 'LAYER 00 · 空白' }); return { vig: .15, grain: .025 };
}
// =====================================================================================  BUILD
async function sc_build(c, t) {
  const hits = [wt(32, /click/), wt(33, /click/)], n = hits.filter(h => t >= h).length, h = hits[Math.max(0, n - 1)];
  const inv = n % 2 === 1; fill(c, inv ? INK.paper : INK.ink); c.save(); shake(c, t, h, 50, .5);
  if (n > 0) { await celDraw(c, clip('S1', 4.3 + (t - h) * .2), { pal: 'face', t, cam: { x: .38, y: .6, z: 1.6 }, misCol: INK.rose, shade: .2, expo: .98 });
    c.save(); c.globalCompositeOperation = inv ? 'multiply' : 'screen'; c.fillStyle = inv ? INK.coral : INK.blue; c.globalAlpha = .5; c.fillRect(0, 0, W, H); c.restore(); }
  const cs = n === 0 ? 1 + (t - 158.14) * .6 : 1; cursor(c, W / 2 - 60, H / 2 - 90, 320 * cs * (1 - .15 * pulse(t, 8)), { col: inv ? INK.ink : INK.paper, stroke: inv ? INK.paper : INK.ink });
  if (n > 0) { const u = (t - h) / .5; if (u < 1) { c.strokeStyle = inv ? INK.ink : INK.paper; c.lineWidth = 20 * (1 - u); c.beginPath(); c.arc(W / 2, H / 2, 150 + u * 900, 0, TAU); c.stroke(); } }
  c.restore(); slam(c, 'RIGHT CLICK', W / 2, H * .85, 170, t, words(n ? 31 + n : 32)[0].t, { font: F.anton, col: INK.coral, shadow: inv ? INK.ink : INK.rose });
  hud(c, t, { col: inv ? INK.ink : INK.paper }); return { mis: 4 };
}
async function sc_eyes(c, t) {
  const lt = t - 164.43; fill(c, INK.navy); c.save(); shake(c, t, 164.43, 30, .4);
  await celDraw(c, clip('S1', 1.4 + lt * .45), { pal: 'face', t, cam: { x: .5, y: .38, z: 2.1 + lt * .15 }, misCol: INK.blue, shade: .2, expo: .98 }); c.restore();
  scrimBottom(c); slamLine(c, t, 34, H * .8, 190, [INK.paper, INK.coral, INK.paper, INK.rose], { shadow: INK.ink });
  whiteIn(c, t, 164.43); hud(c, t); return { mis: 3 };
}
// =====================================================================================  FINAL CHORUS
async function sc_S(c, t) {
  const r = words(35)[0].t, k = wt(35, /click/); fill(c, INK.navy); c.save(); shake(c, t, r, 34, .4); shake(c, t, k, 26, .3);
  await celDraw(c, sdFrame('ST', t), { pal: 'night', t, cam: { x: .5, y: .5, z: 1.05 }, misCol: INK.rose, shade: .26 }); c.restore();
  scrimBottom(c, .7);
  if (t < k + .5) { slam(c, 'RIGHT', W * .5 - 410, H * .76, 300, t, r, { font: F.anton, col: INK.paper, shadow: INK.rose }); slam(c, 'CLICK!', W * .5 + 390, H * .76, 300, t, k, { font: F.anton, col: INK.coral, shadow: INK.ink }); }
  else { const j = words(35).at(-1); c.save(); c.globalAlpha = clamp((t - j.t) / .2); vjp(c, j.w, W - 150, 150, 84, INK.paper, clamp((t - j.t) / 2)); c.restore(); }
  whiteIn(c, t, r); hud(c, t); return { mis: 2.5 };
}
async function sc_T(c, t) {
  fill(c, INK.navy); await celDraw(c, sdFrame('ST', t), { pal: 'night', t, cam: { x: .5, y: .5, z: 1.05 }, misCol: INK.rose, shade: .26 });
  c.save(); c.globalAlpha = clamp((t - 170.66) / .2); vjp(c, '千のレイヤーが', W - 150, 150, 84, INK.paper, clamp((t - 170.66) / 1.3));
  if (t > wt(36, /星/)) vjp(c, '星のように輝く', W - 260, 150, 84, INK.coral, clamp((t - wt(36, /星/)) / 1.3)); c.restore();
  hud(c, t); return {};
}
async function sc_menu3(c, t) {
  const li = 37, nw = words(li)[0].t, fl = wt(li, /file/), cp = wt(li, /copy/), mv = wt(li, /move/), jp = words(li).at(-1).t;
  fill(c, INK.navy); await celDraw(c, 'img/set_layers.jpg', { pal: 'night', t, cam: { x: .5, y: .4 - (t - 173.56) * .02, z: 1.2 }, misCol: INK.rose });
  if (t < jp) {
    const hi = t < fl ? -1 : t < cp ? 0 : t < mv ? 1 : 2; c.save(); shake(c, t, [fl, cp, mv][Math.max(0, hi)], 22, .25);
    ctxMenu(c, W / 2 - 330, 220, 1.3, MENU.slice(0, 3), hi, clamp((t - nw) / .2), { shadow: INK.rose }); c.restore();
    const lab = hi < 0 ? 'NEW' : ['NEW FILE', 'COPY', 'MOVE'][hi], at = hi < 0 ? nw : [fl, cp, mv][hi];
    slam(c, lab, W / 2, H * .83, 260, t, at, { font: F.anton, col: INK.paper, shadow: [INK.make, INK.copy, INK.send][Math.max(0, hi)], from: 1.8 });
  } else {
    // all three at once: a file card copies and flies into place
    const u = clamp((t - jp) / 1.2); for (let i = 0; i < 5; i++) { const x = lerp(W / 2, 260 + i * 350, E.outC(clamp(u * 1.4 - i * .08))); c.save(); c.translate(x, H * .42); c.rotate((1 - u) * (i - 2) * .2);
      c.fillStyle = INK.paper; c.strokeStyle = INK.ink; c.lineWidth = 5; c.beginPath(); c.roundRect(-90, -120, 180, 240, 14); c.fill(); c.stroke(); c.fillStyle = [INK.make, INK.copy, INK.send, INK.nav, INK.coral][i]; c.fillRect(-60, -80, 120, 20); c.restore(); }
    c.save(); c.globalAlpha = clamp((t - jp) / .2); vjp(c, '在るべき未来へ', W - 150, 150, 92, INK.paper, clamp((t - jp) / 2.4)); c.restore();
  }
  hud(c, t); return {};
}
async function sc_U(c, t) {
  fill(c, INK.navy); await celDraw(c, sdFrame('UV', t), { pal: 'dawn', t, cam: { x: .5, y: .5, z: 1.05 }, misCol: INK.rose, shade: .24 });
  scrimBottom(c, .55); sub(c, t, 38, { en: 'When the wave pulls back, every name comes home' }); hud(c, t, { layer: 'LAYER 07 · RESTORED' }); return {};
}
async function sc_V(c, t) {
  fill(c, INK.navy); await celDraw(c, sdFrame('UV', t), { pal: 'dawn', t, cam: { x: .5, y: .5, z: 1.04 + (t - 185) * .01 }, misCol: INK.rose, shade: .24 });
  const im = wt(40, /I'm/);
  if (t < im) { c.save(); c.globalAlpha = clamp((t - 185.03) / .2); vjp(c, '混沌の果てで', W - 150, 150, 92, INK.paper, clamp((t - 185.03) / 1.8)); c.restore(); }
  else { c.save(); shake(c, t, im, 20, .4); slam(c, "I'M", W * .3, H * .8, 230, t, im, { font: F.anton, col: INK.paper, shadow: INK.rose }); slam(c, 'HERE', W * .62, H * .8, 300, t, wt(40, /here/), { font: F.anton, col: INK.coral, shadow: INK.navy }); c.restore(); }
  hud(c, t, { layer: 'LAYER 07 · RESTORED' }); return {};
}
// =====================================================================================  OUTRO
async function sc_putright(c, t) {
  const ws = words(41); evaCard(c, [{ text: 'PUT IT', x: 150, y: 460, size: 250, font: F.anton, sx: 1, col: t >= ws[1].t ? INK.paper : '#0E0F13' },
    { text: 'ALL RIGHT', x: 150, y: 760, size: 300, font: F.anton, sx: 1, col: t >= ws[2].t ? INK.coral : '#0E0F13' }, { text: '全部 元の場所へ', x: W - 150, y: H - 120, size: 70, align: 'right' }], { bg: '#0E0F13' });
  whiteIn(c, t, ws[0].t); return { grain: .06 };
}
async function sc_end(c, t) {
  const lt = t - 193.3; fill(c, INK.navy);
  await celDraw(c, 'img/K_end.jpg', { pal: 'dawn', t, cam: { x: .5, y: .5, z: 1.35 - lt * .03 }, misCol: INK.rose, shade: .22 });
  if (t < 194) { c.save(); c.globalAlpha = 1 - (t - 193.3) / .7; c.fillStyle = '#0E0F13'; c.fillRect(0, 0, W, H); c.restore(); }
  hud(c, t, { layer: 'LAYER 07 · RESTORED' }); return { vig: .3 };
}
async function sc_card(c, t) {
  const k = 203.6; fill(c, '#0E0F13');
  if (t < k) { cursor(c, W / 2 - 30, H / 2 - 50, 110 * (1 - .12 * clamp((t - k + .15) / .15))); return { grain: .06 }; }
  evaCard(c, [{ text: 'UNDER THE RIGHT CLICK', x: W / 2, y: H / 2 - 20, size: 150, font: F.anton, sx: 1, align: 'center' }, { text: '右クリックの向こう', x: W / 2, y: H / 2 + 110, size: 72, align: 'center', col: INK.coral },
    { text: 'RightKit  ·  Riko', x: W / 2, y: H - 120, size: 44, font: F.mono, sx: 1, align: 'center', col: '#8C93A6' }], { bg: '#0E0F13' });
  whiteIn(c, t, k, .15); const fo = clamp((t - 207.2) / .9); if (fo > 0) { c.fillStyle = `rgba(0,0,0,${fo})`; c.fillRect(0, 0, W, H); }
  return { grain: .06 };
}

const TL = [
  [0, sc_boot], [2.27, sc_alert], [4.55, sc_city], [7.8, sc_A],
  [11.2, sc_B], [16.76, sc_C], [22.18, sc_path], [25.85, sc_lost], [29.48, sc_finger], [33.83, sc_E],
  [38.9, sc_countAt(8)], [40.19, sc_clickAt(9)], [43.5, sc_bloomAt(10, 11)], [51.0, sc_F], [55.36, sc_rcrnAt(13)], [56.89, sc_G],
  [65.12, sc_H], [70.45, sc_draft], [76.22, sc_I], [81.3, sc_J], [85.14, sc_signal], [90.59, sc_K],
  [96.6, sc_countAt(21)], [99.47, sc_clickAt(22, .56)], [102.8, sc_bloomAt(23, 24)], [110.35, sc_wave2], [114.64, sc_rcrnAt(26, [INK.coral, INK.paper, INK.ink, INK.rose])], [116.09, sc_O],
  [126.05, sc_montage], [133.52, sc_P], [149.72, sc_archived],
  [158.14, sc_build], [164.43, sc_eyes],
  [167.25, sc_S], [170.66, sc_T], [173.56, sc_menu3], [178.4, sc_U], [182.46, sc_rcrnAt(39, [INK.rose, INK.paper, INK.coral, INK.ink])], [185.03, sc_V],
  [191.33, sc_putright], [193.3, sc_end], [203.0, sc_card],
];
async function drawTimeline(c, t) { let i = TL.length - 1; while (i > 0 && TL[i][0] > t) i--; c.save(); const o = await TL[i][1](c, t); c.restore(); return o; }
