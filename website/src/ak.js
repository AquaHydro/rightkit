// ak-ui theme only (/ak/). Content and the first profile image render without this module.
import { createParticleField } from "./ak-ui/js/site/particles.mjs";
import { createDashboardDepth } from "./ak-ui/js/dashboard-depth.mjs";
import { createMediaGallery } from "./ak-ui/js/site/gallery.mjs";

const controllers = [];
const fields = [...document.querySelectorAll(".ak-particle-field")].map((canvas) => {
  const field = createParticleField(canvas, { pattern: canvas.dataset.pattern, count: 420, color: "#ff7973" });
  controllers.push(field);
  return field;
});
const toggles = [...document.querySelectorAll("[data-motion-toggle]")];
const reduce = matchMedia("(prefers-reduced-motion: reduce)");
const video = document.querySelector(".ak-hero-video");
let motionOn = true;
let heroVisible = true;

// Load the optional video only when the asset exists; the first poster is static.
if (video) {
  const source = video.querySelector("source[data-src]");
  video.addEventListener("error", () => { video.dataset.ready = "false"; });
  video.addEventListener("playing", () => { video.dataset.ready = "true"; });
  video.addEventListener("pause", () => { video.dataset.ready = "false"; });
  if (source && !reduce.matches) { source.src = source.dataset.src; video.load(); }
}

function syncMotion() {
  const canMove = motionOn && !reduce.matches;
  if (reduce.matches) {
    document.querySelector(".ak-profile-outgoing")?.remove();
    document.querySelectorAll(".ak-profile-arriving").forEach((item) => item.classList.remove("ak-profile-arriving"));
  }
  const hasMotion = fields.some((field) => field.renderer !== "static") || Boolean(video);
  toggles.forEach((toggle) => {
    toggle.hidden = reduce.matches || !hasMotion;
    toggle.setAttribute("aria-pressed", String(motionOn));
  });
  fields.forEach((field) => canMove ? field.resume() : field.pause());
  if (video) {
    const source = video.querySelector("source[data-src]");
    if (canMove && source && !source.src) { source.src = source.dataset.src; video.load(); }
    if (canMove && heroVisible && !document.hidden && video.querySelector("source")?.src) video.play().catch(() => {});
    else video.pause();
  }
}
toggles.forEach((toggle) => toggle.addEventListener("click", () => { motionOn = !motionOn; syncMotion(); }));
reduce.addEventListener("change", syncMotion);
document.addEventListener("visibilitychange", syncMotion);
const heroObserver = video && "IntersectionObserver" in window ? new IntersectionObserver((entries) => {
  heroVisible = entries[0]?.isIntersecting ?? false;
  syncMotion();
}, { threshold: .05 }) : null;
if (heroObserver) heroObserver.observe(video.closest(".hero"));
syncMotion();

// Track all eleven chapters in normal document scroll. Native anchors remain available without JS.
const sections = ["new", "send", "open", "toolbox", "workbench", "trust", "more", "profile", "pricing", "faq", "links"]
  .map((id) => document.getElementById(id)).filter(Boolean);
const indexNumber = document.querySelector("[data-ak-index-current]");
const indexTitle = document.querySelector("[data-ak-index-title]");
const giant = document.querySelector(".ak-section-index-giant");
const navLinks = [...document.querySelectorAll(".ak-nav-links a[href^='#']")];
let scrollFrame = 0;
function updateSection() {
  scrollFrame = 0;
  let active = -1;
  const marker = window.innerHeight * .35;
  sections.forEach((section, i) => { if (section.getBoundingClientRect().top <= marker) active = i; });
  const current = sections[active];
  const number = String(active + 1).padStart(2, "0");
  if (indexNumber) indexNumber.textContent = number;
  if (giant) giant.textContent = number;
  if (indexTitle) indexTitle.textContent = !current ? "RIGHTKIT" : current.id === "profile" ? "RIKO PROFILE" : current.querySelector(".section-label")?.textContent?.replace(/^\/\/\s*\d+\s*/, "")?.trim() || current.id.toUpperCase();
  navLinks.forEach((link) => {
    if (current && link.hash === `#${current.id}`) link.setAttribute("aria-current", "location");
    else link.removeAttribute("aria-current");
  });
}
const requestSection = () => { if (!scrollFrame) scrollFrame = requestAnimationFrame(updateSection); };
window.addEventListener("scroll", requestSection, { passive: true });
window.addEventListener("resize", requestSection);
updateSection();

const galleryRoot = document.querySelector("[data-ak-profile-gallery]");
if (galleryRoot) {
  const stage = galleryRoot.querySelector("[data-ak-gallery-stage]");
  const items = [...galleryRoot.querySelectorAll("[data-ak-gallery-item]")];
  const echo = galleryRoot.querySelector(".ak-profile-echo");
  const progress = galleryRoot.querySelector(".ak-profile-progress span");
  if (progress) progress.style.width = `${100 / items.length}%`;
  let previous = 0;
  let initialized = false;
  let echoTimer = 0;
  const gallery = createMediaGallery(galleryRoot, {
    duration: 0,
    onChange(index) {
      if (index < 0) return;
      const nextImage = items[index]?.querySelector("img");
      items.forEach((item) => item.classList.remove("ak-profile-arriving"));
      if (initialized && index !== previous && !reduce.matches) {
        const oldImage = items[previous]?.querySelector("img");
        if (oldImage) {
          stage.querySelector(".ak-profile-outgoing")?.remove();
          const outgoing = oldImage.cloneNode();
          outgoing.alt = "";
          outgoing.setAttribute("aria-hidden", "true");
          outgoing.className = "ak-profile-outgoing";
          stage.append(outgoing);
          outgoing.addEventListener("animationend", () => outgoing.remove(), { once: true });
        }
        items[index].classList.add("ak-profile-arriving");
        items[index].addEventListener("animationend", () => items[index].classList.remove("ak-profile-arriving"), { once: true });
      }
      clearTimeout(echoTimer);
      if (echo && nextImage) {
        if (initialized && index !== previous && !reduce.matches) {
          echo.classList.add("ak-profile-echo-switch");
          echoTimer = setTimeout(() => { echo.src = nextImage.src; echo.classList.remove("ak-profile-echo-switch"); }, 350);
        } else {
          echo.src = nextImage.src;
          echo.classList.remove("ak-profile-echo-switch");
        }
      }
      if (progress) progress.style.translate = `${index * 100}% 0`;
      previous = index;
      initialized = true;
    },
  });
  controllers.push(gallery);
  controllers.push({ destroy: () => clearTimeout(echoTimer) });
}

// Term browser: the page's own line icons are rasterised and sampled into points,
// then the points drift between shapes. Reduced motion keeps the static SVG.
const worldRoot = document.querySelector("[data-ak-world]");
if (worldRoot) {
  const choices = [...worldRoot.querySelectorAll("[data-ak-world-select]")];
  const canvas = worldRoot.querySelector("[data-ak-world-canvas]");
  const ctx = canvas.getContext("2d");
  const staticUse = worldRoot.querySelector("[data-ak-world-static-use]");
  const title = worldRoot.querySelector("[data-ak-world-title]");
  const body = worldRoot.querySelector("[data-ak-world-body]");
  const counter = worldRoot.querySelector("[data-ak-world-current]");
  const progress = worldRoot.querySelector(".ak-world-progress > span");
  const COUNT = 1400;
  const shapes = new Map();
  const dots = Array.from({ length: COUNT }, (_, i) => ({ x: Math.random(), y: Math.random(), fx: 0, fy: 0, tx: 0, ty: 0, phase: i * 2.399, coral: i % 9 === 0 }));
  let index = 0, morphStart = 0, frame = 0, visible = false, width = 0, height = 0;

  function sample(icon) {
    if (shapes.has(icon)) return shapes.get(icon);
    const symbol = document.getElementById(`i-${icon}`);
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${symbol.getAttribute("viewBox")}" width="240" height="240" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">${symbol.innerHTML}</svg>`;
    const task = new Promise((resolve) => {
      const img = new Image();
      img.onload = () => {
        const off = document.createElement("canvas");
        off.width = off.height = 240;
        const c = off.getContext("2d", { willReadFrequently: true });
        c.drawImage(img, 0, 0);
        const data = c.getImageData(0, 0, 240, 240).data;
        const hits = [];
        for (let y = 0; y < 240; y++) for (let x = 0; x < 240; x++) if (data[(y * 240 + x) * 4 + 3] > 100) hits.push([x / 240, y / 240]);
        // Deterministic shuffle so the same icon always gets the same layout.
        for (let i = hits.length - 1, seed = 7; i > 0; i--) { seed = (seed * 16807) % 2147483647; const j = seed % (i + 1); [hits[i], hits[j]] = [hits[j], hits[i]]; }
        resolve(Array.from({ length: COUNT }, (_, i) => hits[i % hits.length]));
      };
      img.src = `data:image/svg+xml,${encodeURIComponent(svg)}`;
    });
    shapes.set(icon, task);
    return task;
  }

  function resize() {
    const rect = canvas.getBoundingClientRect();
    const dpr = Math.min(devicePixelRatio || 1, 2);
    width = rect.width; height = rect.height;
    canvas.width = Math.round(width * dpr); canvas.height = Math.round(height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  function draw(now) {
    const size = Math.min(width, height) * .9;
    const left = (width - size) / 2, top = (height - size) / 2;
    const idle = motionOn && !reduce.matches;
    ctx.clearRect(0, 0, width, height);
    for (let i = 0; i < COUNT; i++) {
      const d = dots[i];
      const t = Math.min(1, Math.max(0, (now - morphStart - (i / COUNT) * 260) / 720));
      const e = 1 - (1 - t) ** 3;
      d.x = d.fx + (d.tx - d.fx) * e;
      d.y = d.fy + (d.ty - d.fy) * e;
      const wobble = idle ? Math.sin(now / 900 + d.phase) * 1.1 : 0;
      ctx.fillStyle = d.coral ? "#ff7973" : "rgba(236, 236, 240, .82)";
      ctx.fillRect(left + d.x * size + wobble, top + d.y * size + Math.cos(now / 1100 + d.phase) * wobble, 1.6, 1.6);
    }
  }

  function loop(now) {
    draw(now);
    const settling = now - morphStart < 1100;
    frame = visible && (settling || (motionOn && !reduce.matches)) ? requestAnimationFrame(loop) : 0;
  }
  const kick = () => { if (!frame && visible) frame = requestAnimationFrame(loop); };

  async function select(next) {
    index = (next + choices.length) % choices.length;
    const choice = choices[index];
    choices.forEach((item, i) => item.setAttribute("aria-pressed", String(i === index)));
    title.textContent = choice.querySelector(".ak-world-term-local").textContent;
    body.textContent = choice.dataset.body;
    counter.textContent = `${String(index + 1).padStart(2, "0")} / ${String(choices.length).padStart(2, "0")}`;
    progress.style.width = `${((index + 1) / choices.length) * 100}%`;
    staticUse.setAttribute("href", `#i-${choice.dataset.icon}`);
    if (reduce.matches) return;
    const target = await sample(choice.dataset.icon);
    if (choices[index] !== choice) return;
    dots.forEach((d, i) => { d.fx = d.x; d.fy = d.y; [d.tx, d.ty] = target[i]; });
    morphStart = performance.now();
    worldRoot.classList.add("ak-world-canvas-ready");
    kick();
  }

  choices.forEach((choice, i) => choice.addEventListener("click", () => select(i)));
  worldRoot.querySelector("[data-ak-world-prev]").addEventListener("click", () => select(index - 1));
  worldRoot.querySelector("[data-ak-world-next]").addEventListener("click", () => select(index + 1));
  worldRoot.querySelector(".ak-world-terms").addEventListener("keydown", (event) => {
    const step = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[event.key];
    if (!step) return;
    event.preventDefault();
    select(index + step);
    choices[index].focus();
  });
  const resizer = new ResizeObserver(() => { resize(); kick(); });
  resizer.observe(canvas);
  const seen = new IntersectionObserver(([entry]) => { visible = entry.isIntersecting; kick(); });
  seen.observe(canvas);
  toggles.forEach((toggle) => toggle.addEventListener("click", kick));
  resize();
  select(0);
  controllers.push({ destroy() { cancelAnimationFrame(frame); resizer.disconnect(); seen.disconnect(); } });
}

// Workbench: a directory row and its scene marker light each other up.
const workbench = document.querySelector(".ak-workbench");
if (workbench) {
  const light = (key) => workbench.querySelectorAll("[data-workbench-key]").forEach((el) => el.classList.toggle("is-lit", el.dataset.workbenchKey === key));
  workbench.querySelectorAll("[data-workbench-key]").forEach((el) => {
    const on = () => light(el.dataset.workbenchKey);
    el.addEventListener("pointerenter", on);
    el.addEventListener("focus", on);
    el.addEventListener("pointerleave", () => light(null));
    el.addEventListener("blur", () => light(null));
  });
}

if (matchMedia("(hover: hover) and (pointer: fine)").matches) {
  document.querySelectorAll(".hero, .cta, .feature, .toolbox").forEach((root) => {
    controllers.push(createDashboardDepth(root, { maxX: 90, maxY: 50 }));
  });
}

window.addEventListener("pagehide", () => {
  controllers.forEach((controller) => controller.destroy());
  video?.pause();
  heroObserver?.disconnect();
  reduce.removeEventListener("change", syncMotion);
  document.removeEventListener("visibilitychange", syncMotion);
  window.removeEventListener("scroll", requestSection);
  window.removeEventListener("resize", requestSection);
  cancelAnimationFrame(scrollFrame);
}, { once: true });
