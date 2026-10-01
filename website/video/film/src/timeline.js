// Pure time -> pixels. Every element state is recomputed from t, so seeking backwards is safe.
// Attributes (times are seconds relative to the shot start):
//   data-in="t [dx dy scale]"   rise and fade in (website: 24px, 0.7s, --ease-out)
//   data-out="t"                fade out over 0.3s
//   data-win="cls@a-b,c-d;..."  toggle classes inside the windows
//   data-pop="t"                file appears with the website's pop keyframes
//   data-menu="a-b"             menu opens from the cursor (scale 0.96 -> 1, 0.18s)
//   data-toast="a-b"            status bar message
//   data-fly="t" data-from data-to  ghost icon flies to the sidebar (main.js flyTo)
//   data-ring="t"               ripple ring (website clip-ping)
//   data-ticker="px/s"          scrolling ticker
//   data-float="period amp"     idle float (website float keyframes)
//   data-path / data-clicks     cursor path segments and click times
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
function bezier(x1, y1, x2, y2) {
  const f = (a, b, s) => 3 * a * s * (1 - s) ** 2 + 3 * b * s * s * (1 - s) + s ** 3;
  return (x) => {
    x = clamp(x);
    let lo = 0, hi = 1;
    for (let i = 0; i < 24; i++) { const m = (lo + hi) / 2; if (f(x1, x2, m) < x) lo = m; else hi = m; }
    return f(y1, y2, (lo + hi) / 2);
  };
}
const easeOut = bezier(0.16, 1, 0.3, 1);        // website --ease-out, the only main curve
const easeMove = bezier(0.45, 0, 0.2, 1);       // main.js moveCursor
const easeFly = bezier(0.5, 0, 0.2, 1);         // main.js flyTo
const windows = (spec) => spec.split(',').map((w) => w.split('-').map(Number));
const inside = (spec, t) => windows(spec).some(([a, b]) => t >= a && t < b);

// Layout position relative to the stage, ignoring transforms (offset* are untransformed).
function pos(el, stage) {
  let x = 0, y = 0;
  for (let n = el; n && n !== stage; n = n.offsetParent) { x += n.offsetLeft; y += n.offsetTop; }
  return {x, y, w: el.offsetWidth, h: el.offsetHeight};
}

function layout(scene) {
  const stage = scene.querySelector('.stage');
  if (!stage) return;
  const maxX = Number(stage.dataset.maxx), maxY = Number(stage.dataset.maxy);
  const resolve = scene._resolve = (spec) => {
    if (Array.isArray(spec)) return {x: spec[0], y: spec[1]};
    const [sel, dx = null, dy = null] = spec.split('|');
    const p = pos(scene.querySelector(sel), stage);
    return {x: p.x + (dx === null ? p.w / 2 : Number(dx)), y: p.y + (dy === null ? p.h / 2 : Number(dy))};
  };
  // Menus open at the cursor and flip or shift to stay on screen, like place() in main.js.
  scene.querySelectorAll('.menu[data-at]').forEach((el) => {
    const p = resolve(el.dataset.at);
    let left = p.x, top = p.y;
    if (left + el.offsetWidth > maxX) left = p.x - el.offsetWidth;
    if (top + el.offsetHeight > maxY) top = Math.max(8, maxY - el.offsetHeight);
    el.style.left = `${left}px`;
    el.style.top = `${top}px`;
    el.style.transformOrigin = `${p.x - left}px ${p.y - top}px`;
  });
  // Submenus sit next to their parent row, as openSub() does.
  scene.querySelectorAll('.menu[data-parent]').forEach((sub) => {
    const row = scene.querySelector(`[data-key="${sub.dataset.parent}"]`);
    const parent = row.closest('.menu');
    let left = parent.offsetLeft + parent.offsetWidth - 3;
    const flip = left + sub.offsetWidth > maxX;
    if (flip) left = parent.offsetLeft - sub.offsetWidth + 3;
    let top = parent.offsetTop + row.offsetTop - 5;
    if (top + sub.offsetHeight > maxY) top = Math.max(8, maxY - sub.offsetHeight);
    sub.style.left = `${left}px`;
    sub.style.top = `${top}px`;
    sub.style.transformOrigin = `${flip ? sub.offsetWidth : 0}px ${parent.offsetTop + row.offsetTop - top}px`;
  });
  scene.querySelectorAll('[data-fly]').forEach((ghost) => {
    const a = pos(scene.querySelector(ghost.dataset.from), stage);
    const b = pos(scene.querySelector(ghost.dataset.to), stage);
    ghost._from = a; ghost._delta = {x: b.x - a.x - 16, y: b.y - a.y - 18};
  });
}

function seekScene(scene, t) {
  scene.querySelectorAll('[data-in],[data-out]').forEach((el) => {
    let o = 1;
    if (el.dataset.in) {
      const [at, dx = 0, dy = 24, s = 1] = el.dataset.in.split(' ').map(Number);
      const u = easeOut((t - at) / 0.7);
      o = clamp((t - at) / 0.45);
      el.style.transform = `translate(${(1 - u) * dx}px, ${(1 - u) * dy}px) scale(${s + (1 - s) * u})`;
    }
    if (el.dataset.out) o *= 1 - clamp((t - Number(el.dataset.out)) / 0.3);
    el.style.opacity = String(o);
  });
  scene.querySelectorAll('[data-win]').forEach((el) => {
    el.dataset.win.split(';').forEach((part) => {
      const [cls, spec] = part.split('@');
      el.classList.toggle(cls, inside(spec, t));
    });
  });
  scene.querySelectorAll('[data-pop]').forEach((el) => {
    const at = Number(el.dataset.pop);
    const u = easeOut((t - at) / 0.5);
    el.style.visibility = t >= at ? 'visible' : 'hidden';
    el.style.opacity = String(u);
    el.style.transform = `scale(${0.6 + 0.4 * u})`;
  });
  scene.querySelectorAll('[data-menu]').forEach((el) => {
    const [a, b] = el.dataset.menu.split('-').map(Number);
    const open = t >= a && t < b;
    // visibility, not display: closed menus keep their size for layout().
    el.style.visibility = open ? 'visible' : 'hidden';
    if (!open) return;
    const u = easeOut((t - a) / 0.18);
    el.style.opacity = String(u);
    el.style.transform = `scale(${0.96 + 0.04 * u})`;
  });
  scene.querySelectorAll('[data-toast]').forEach((el) => {
    const [a, b] = el.dataset.toast.split('-').map(Number);
    const o = clamp((t - a) / 0.25) * (1 - clamp((t - b) / 0.25));
    el.style.opacity = String(o);
    el.style.transform = `translateY(${(1 - easeOut((t - a) / 0.35)) * 8}px)`;
  });
  scene.querySelectorAll('[data-fly]').forEach((el) => {
    const at = Number(el.dataset.fly);
    const u = (t - at) / 0.52;
    el.style.display = u >= 0 && u < 1 ? 'block' : 'none';
    if (u < 0 || u >= 1 || !el._from) return;
    const e = easeFly(u);
    el.style.left = `${el._from.x}px`;
    el.style.top = `${el._from.y}px`;
    el.style.opacity = String(1 - 0.8 * e);
    el.style.transform = `translate(${el._delta.x * e}px, ${el._delta.y * e}px) scale(${1 - 0.7 * e})`;
  });
  scene.querySelectorAll('[data-ring]').forEach((el) => {
    const u = (t - Number(el.dataset.ring)) / 0.55;
    el.style.opacity = u < 0 || u > 1 ? '0' : String(1 - easeOut(u));
    el.style.transform = `scale(${0.4 + 2.2 * easeOut(clamp(u))})`;
  });
  scene.querySelectorAll('[data-ticker]').forEach((el) => {
    el.style.transform = `translateX(${-t * Number(el.dataset.ticker)}px)`;
  });
  scene.querySelectorAll('[data-float]').forEach((el) => {
    const [period, amp] = el.dataset.float.split(' ').map(Number);
    el.style.transform = `translateY(${-amp * (0.5 - 0.5 * Math.cos((2 * Math.PI * t) / period))}px)`;
  });
  scene.querySelectorAll('.fake-cursor[data-path]').forEach((el) => {
    const segs = JSON.parse(el.dataset.path);
    let p = scene._resolve(segs[0][2]);
    for (const [a, b, to] of segs) {
      if (t < a) break;
      const q = scene._resolve(to);
      const u = easeMove((t - a) / Math.max(b - a, 1e-3));
      p = {x: p.x + (q.x - p.x) * u, y: p.y + (q.y - p.y) * u};
    }
    const press = (el.dataset.clicks || '').split(',').filter(Boolean).map(Number)
      .some((c) => t >= c && t < c + 0.25) ? 0.85 : 1;
    el.style.left = `${p.x}px`;
    el.style.top = `${p.y}px`;
    el.style.transform = `scale(${press})`;
  });
}

window.seek = function (seconds) {
  const t = clamp(Number(seconds) || 0, 0, window.FILM.duration - 1 / window.FILM.fps);
  document.querySelectorAll('.shot').forEach((scene) => {
    const start = Number(scene.dataset.start), end = Number(scene.dataset.end);
    const active = t >= start && t < end + 0.001;
    // Incoming shot fades over the previous one for 0.25s.
    scene.style.opacity = active ? String(start === 0 ? 1 : clamp((t - start) / 0.25)) : '0';
    scene.style.visibility = active || (t >= end && t < end + 0.25) ? 'visible' : 'hidden';
    if (t >= end && t < end + 0.25) scene.style.opacity = '1';
    if (scene.style.visibility === 'visible') { layout(scene); seekScene(scene, t - start); }
  });
  window.CURRENT_TIME = t;
};
window.seek(0);
let clockOrigin = null, request = null;
window.stopFilm = () => { cancelAnimationFrame(request); request = null; clockOrigin = null; };
window.playFilm = (from = 0) => {
  window.stopFilm();
  const loop = (now) => {
    clockOrigin ??= now - from * 1000;
    const t = (now - clockOrigin) / 1000;
    window.seek(t);
    if (t < window.FILM.duration) request = requestAnimationFrame(loop);
  };
  request = requestAnimationFrame(loop);
};
