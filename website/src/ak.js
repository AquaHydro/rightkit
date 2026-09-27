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

// Track all nine chapters in normal document scroll. Native anchors remain available without JS.
const sections = ["new", "send", "open", "toolbox", "trust", "more", "profile", "pricing", "faq"]
  .map((id) => document.getElementById(id)).filter(Boolean);
const indexNumber = document.querySelector("[data-ak-index-current]");
const indexTitle = document.querySelector("[data-ak-index-title]");
const giant = document.querySelector(".ak-section-index-giant");
const navLinks = [...document.querySelectorAll(".ak-nav-links a[href^='#']")];
let scrollFrame = 0;
function updateSection() {
  scrollFrame = 0;
  let active = 0;
  const marker = window.innerHeight * .35;
  sections.forEach((section, i) => { if (section.getBoundingClientRect().top <= marker) active = i; });
  const current = sections[active];
  if (!current) return;
  const number = String(active + 1).padStart(2, "0");
  if (indexNumber) indexNumber.textContent = number;
  if (giant) giant.textContent = number;
  if (indexTitle) indexTitle.textContent = current.id === "profile" ? "RIKO PROFILE" : current.querySelector(".section-label")?.textContent?.replace(/^\/\/\s*\d+\s*/, "")?.trim() || current.id.toUpperCase();
  navLinks.forEach((link) => {
    if (link.hash === `#${current.id}`) link.setAttribute("aria-current", "location");
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
