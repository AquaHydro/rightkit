// ak-ui theme only (/ak/): particle fields and pointer parallax, from the vendored ak-ui 1.1.0 controllers.
import { createParticleField } from "./ak-ui/js/site/particles.mjs";
import { createDashboardDepth } from "./ak-ui/js/dashboard-depth.mjs";

const fields = [...document.querySelectorAll(".ak-particle-field")].map((canvas) =>
  createParticleField(canvas, { pattern: canvas.dataset.pattern, count: 1800, color: "#ff7973" }));

// One setting for every field; each field's section carries its own toggle so the control is always nearby.
const toggles = [...document.querySelectorAll("[data-motion-toggle]")];
const reduce = matchMedia("(prefers-reduced-motion: reduce)");
// Fields already freeze under reduced motion; the toggles only show when there is motion to stop.
const syncToggles = () => {
  const hidden = reduce.matches || fields.every((field) => field.renderer === "static");
  toggles.forEach((toggle) => { toggle.hidden = hidden; });
};
syncToggles();
reduce.addEventListener("change", syncToggles);
toggles.forEach((toggle) => toggle.addEventListener("click", () => {
  const on = toggle.getAttribute("aria-pressed") !== "true";
  toggles.forEach((other) => other.setAttribute("aria-pressed", String(on)));
  fields.forEach((field) => (on ? field.resume() : field.pause()));
}));

// Depth follows a real mouse only; touch and pen never move the layers.
if (matchMedia("(hover: hover) and (pointer: fine)").matches) {
  document.querySelectorAll(".hero, .cta, .feature, .toolbox").forEach((root) => createDashboardDepth(root, { maxX: 90, maxY: 50 }));
}
