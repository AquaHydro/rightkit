// core.js: constants, timing grid, inks, easing, rng, asset cache, lyrics.
const W = 1920, H = 1080, FPS = 30;
// Under the Right Click: 170 BPM, downbeat grid measured from the Suno master (analyze in song/)
const BPM = 170, BEAT = 60 / BPM, PHASE = 30.299, BAR = BEAT * 4;
const DUR = 208.15;

// Riko inks: brand coral pair + night blues, printed on warm paper
const INK = {
  paper: '#FAF7F5', paper2: '#EFE8E2', ink: '#2A2B31', coral: '#FF8F6C', rose: '#FF5175',
  blue: '#1D5FD1', navy: '#12203F', cream: '#FFF4EC', mist: '#B9C3D6',
  claude: '#FF8F6C', pink: '#FF5175', lcl: '#FF8F6C', alarm: '#FF5175',   // aliases for the inherited fx/type code
  make: '#34C759', copy: '#007AFF', send: '#00A3BF', nav: '#FF8D28',
};
const hex2rgb = h => [parseInt(h.slice(1, 3), 16) / 255, parseInt(h.slice(3, 5), 16) / 255, parseInt(h.slice(5, 7), 16) / 255];

// palettes for the cel pass (max 10 inks each)
const PAL = {
  night: ['#12203F', '#1D5FD1', '#FAF7F5', '#2A2B31', '#FF8F6C', '#FF5175', '#F6D5C4', '#E9A48C', '#B9C3D6', '#5A6FA8'],
  face:  ['#12203F', '#1D5FD1', '#FAF7F5', '#2A2B31', '#FF8F6C', '#FF5175', '#F6D5C4', '#E9A48C', '#8E2F3A', '#FCE7DC'],
  rain:  ['#2A2B31', '#3C4150', '#5A6FA8', '#8C93A6', '#B9C3D6', '#FAF7F5', '#E6DCD6', '#C9B8B0', '#FF8F6C', '#1A1C22'],
  blank: ['#FAF7F5', '#EFE8E2', '#B9C3D6', '#2A2B31', '#FF8F6C', '#FF5175', '#F6D5C4', '#E9A48C', '#8E2F3A', '#FCE7DC'],
  dawn:  ['#12203F', '#3A3F7A', '#FF8F6C', '#FF5175', '#FFF4EC', '#FAF7F5', '#2A2B31', '#F6D5C4', '#E9A48C', '#FFC9A8'],
  mono:  ['#2A2B31', '#FAF7F5', '#8C857A'],
};

// ---- timing
const beatOf = t => (t - PHASE) / BEAT;
const beatT = b => PHASE + b * BEAT;
const snap16 = t => PHASE + Math.round((t - PHASE) / (BEAT / 4)) * (BEAT / 4);
// decaying pulse on every beat (1 at the beat, fades)
const pulse = (t, k = 6, div = 1) => { const b = beatOf(t) * div; return b < 0 ? 0 : Math.exp(-(b - Math.floor(b)) * k); };
const onTwos = t => Math.floor(t * 12) / 12;          // animate on twos (12 drawings/s)
const boilSeed = t => Math.floor(t * 12);

// ---- math / easing
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const lerp = (a, b, u) => a + (b - a) * u;
const inv = (a, b, x) => clamp((x - a) / (b - a));
const E = {
  lin: u => u, inQ: u => u * u, outQ: u => 1 - (1 - u) * (1 - u), ioQ: u => u < .5 ? 2 * u * u : 1 - Math.pow(-2 * u + 2, 2) / 2,
  outC: u => 1 - Math.pow(1 - u, 3), inC: u => u * u * u, outX: u => u >= 1 ? 1 : 1 - Math.pow(2, -10 * u), inX: u => u <= 0 ? 0 : Math.pow(2, 10 * u - 10),
  ioX: u => u <= 0 ? 0 : u >= 1 ? 1 : u < .5 ? Math.pow(2, 20 * u - 10) / 2 : (2 - Math.pow(2, -20 * u + 10)) / 2,
  outB: u => { const c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * Math.pow(u - 1, 3) + c1 * Math.pow(u - 1, 2); },
  outEl: u => u === 0 ? 0 : u === 1 ? 1 : Math.pow(2, -10 * u) * Math.sin((u * 10 - .75) * (2 * Math.PI) / 3) + 1,
};
function rng(seed) { let s = (seed * 2654435761) >>> 0 || 1; return () => { s ^= s << 13; s >>>= 0; s ^= s >> 17; s ^= s << 5; s >>>= 0; return s / 4294967296; }; }
const hash = (a, b = 0) => { const r = rng(a * 7919 + b * 104729 + 13); r(); return r(); };
// smooth 1D value noise
const noise1 = x => { const i = Math.floor(x), f = x - i, u = f * f * (3 - 2 * f); return lerp(hash(i), hash(i + 1), u) * 2 - 1; };

// ---- assets
const _cache = new Map();
function img(src) {
  if (!_cache.has(src)) _cache.set(src, new Promise((res, rej) => { const i = new Image(); i.onload = () => res(i); i.onerror = () => rej(new Error('img ' + src)); i.src = src; }));
  return _cache.get(src);
}
// Seedance shot frames: extracted at 24 fps into frames/<shot>/NNNN.jpg, drawn on twos
const SHOTS = {}; // filled from frames/index.json {A:{n:120, t0:1.0}, ...}
function shotFrame(shot, tl, twos = true) {
  const s = SHOTS[shot]; if (!s) return null;
  const tt = twos ? onTwos(tl) : tl;
  const i = clamp(Math.round(tt * 24), 0, s.n - 1);
  return img(`frames/${shot}/${String(i + 1).padStart(4, '0')}.jpg`);
}

// ---- lyrics: LW (lyrics.js) holds Suno's per-word timing, LY is the per-line view the type engine reads
const LY = LW.map(l => [l[0][0], l.at(-1)[1], l.map(w => w[2]).join(' ')]);
const lyricIdx = t => LY.findIndex(l => t >= l[0] && t < l[1] + 0.25);
const words = li => LW[li].map((w, i) => ({ w: w[2], t: w[0], i }));
