// Language preference is separate from the demo and theme controllers.
// Explicit locale URLs stay readable regardless of browser/storage preferences.
(() => {
  "use strict";
  const configNode = document.getElementById("language-data");
  if (!configNode) return;
  const config = JSON.parse(configNode.textContent);
  const preferenceKey = "rightkit.website.language";
  const currentURL = new URL(location.href);
  const choices = config.languages;
  const supported = (key) => choices.find((choice) => choice.key === key);
  const readPreference = () => {
    try { return localStorage.getItem(preferenceKey); } catch { return null; }
  };
  const matchLanguage = () => {
    for (const language of navigator.languages || [navigator.language]) {
      const key = String(language).toLowerCase().split(/[-_]/)[0];
      if (supported(key)) return key;
    }
    return "zh";
  };
  const destination = (choice) => {
    const url = new URL(choice.href, currentURL);
    const parameters = new URLSearchParams(currentURL.search);
    parameters.delete("lang");
    if (choice.key === "zh") parameters.set("lang", "zh");
    url.search = parameters.toString();
    url.hash = location.hash;
    return url;
  };

  // Only the default Chinese entry negotiates language. /en/, /ja/ and /ko/
  // (including /ak/ and privacy variants) always honor their explicit path.
  if (config.defaultEntry && currentURL.searchParams.get("lang") !== "zh") {
    const stored = readPreference();
    const preferred = supported(stored) ? stored : matchLanguage();
    if (preferred !== config.current) location.replace(destination(supported(preferred)).href);
  }

  document.addEventListener("DOMContentLoaded", () => {
    const links = document.querySelectorAll("[data-language]");
    for (const link of links) {
      link.addEventListener("click", (event) => {
        if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        const choice = supported(link.dataset.language);
        if (!choice) return;
        // Navigation still works when persistent storage is blocked.
        try { localStorage.setItem(preferenceKey, choice.key); } catch {}
        link.href = destination(choice).href;
      });
    }
    const selectors = document.querySelectorAll(".language-switch");
    document.addEventListener("click", (event) => {
      for (const selector of selectors) {
        if (!selector.contains(event.target)) selector.open = false;
      }
    });
    document.addEventListener("keydown", (event) => {
      if (event.key !== "Escape") return;
      for (const selector of selectors) {
        if (!selector.open) continue;
        selector.open = false;
        selector.querySelector("summary").focus();
        event.preventDefault();
      }
    });
  });
})();
