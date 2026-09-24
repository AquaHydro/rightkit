// RightKit website: scroll reveal, navigation state and the right-click demo.
(() => {
  "use strict";

  const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)");
  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];

  // Navigation gets a background once the page scrolls.
  const nav = $("[data-nav]");
  const onScroll = () => nav.classList.toggle("scrolled", scrollY > 8);
  addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  // Reveal on scroll, staggered within the same parent.
  const reveal = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      const siblings = $$(":scope > .reveal", entry.target.parentElement);
      const index = Math.max(0, siblings.indexOf(entry.target));
      entry.target.style.setProperty("--stagger", `${Math.min(index, 6) * 60}ms`);
      entry.target.classList.add("in");
      reveal.unobserve(entry.target);
    });
  }, { rootMargin: "0px 0px -8% 0px" });
  $$(".reveal").forEach((el) => reveal.observe(el));

  // Pause looping animations while they are off screen.
  const looping = new IntersectionObserver((entries) => {
    entries.forEach((entry) => entry.target.classList.toggle("paused", !entry.isIntersecting));
  });
  $$(".hero-stage, .ticker, .cta-art").forEach((el) => looping.observe(el));

  const stage = $("[data-stage]");
  if (!stage) return;

  const data = JSON.parse($("#demo-data").textContent);
  const toolGroups = JSON.parse($("#tool-data").textContent);
  const content = $("[data-content]", stage);
  const list = $("[data-files]", stage);
  const toast = $("[data-toast]", stage);
  const cursor = $("[data-cursor]");
  const svg = (id, cls = "ic") => `<svg class="${cls}" aria-hidden="true"><use href="#i-${id}"/></svg>`;
  const format = (template, values) => template.replace(/\{(\w+)\}/g, (_, key) => values[key] ?? "");
  const escapeHTML = (text) => text.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  const docColors = { docx: "#185abd", xlsx: "#107c41", pptx: "#c43e1c", md: "#3a3a3c", rtf: "#7d5bd6" };

  // Demo state: the files on the simulated desktop.
  let files = data.files.map((file, id) => ({ ...file, id, hidden: false, extHidden: false }));
  let nextId = files.length;
  let selectedId = null;
  let cutId = null;
  let autoplay = null;
  let interacted = false;

  const current = data.places.find((place) => place.path === data.folder);
  $$(".finder-side li", stage).forEach((li) => li.classList.toggle("current", li.dataset.place === data.folder));

  const displayName = (file) => (file.extHidden && file.ext ? file.name.slice(0, -(file.ext.length + 1)) : file.name);
  const iconHTML = (file) => {
    if (file.kind === "folder") return `<span class="folder-shape"></span>`;
    if (file.kind === "image") return `<span class="thumb"></span>`;
    return `<span class="doc" data-ext="${file.ext}" data-label="${file.ext}"></span>`;
  };

  function renderFiles(enterId) {
    list.innerHTML = "";
    files.forEach((file) => {
      const li = document.createElement("li");
      const button = document.createElement("button");
      button.type = "button";
      button.className = "file";
      button.dataset.id = file.id;
      button.classList.toggle("selected", file.id === selectedId);
      button.classList.toggle("cut", file.id === cutId);
      button.classList.toggle("hidden-item", file.hidden);
      button.classList.toggle("enter", file.id === enterId);
      button.innerHTML = `<span class="file-icon">${iconHTML(file)}</span><span class="file-name">${escapeHTML(displayName(file))}</span>`;
      li.append(button);
      list.append(li);
    });
  }

  const fileById = (id) => files.find((file) => file.id === id);
  const buttonFor = (id) => $(`.file[data-id="${id}"]`, list);

  function select(id) {
    selectedId = id;
    $$(".file", list).forEach((el) => el.classList.toggle("selected", Number(el.dataset.id) === id));
  }

  let toastTimer;
  function say(message) {
    toast.textContent = message;
    toast.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("show"), 3200);
  }

  function uniqueName(base, ext, taken = files.map((file) => file.name)) {
    const make = (n) => (n === 1 ? base : `${base} ${n}`) + (ext ? `.${ext}` : "");
    let n = 1;
    while (taken.includes(make(n))) n += 1;
    return make(n);
  }

  function copyText(text) {
    navigator.clipboard?.writeText(text).catch(() => {});
    say(format(data.toast.copied, { text }));
  }

  function flyTo(file, placePath) {
    const from = buttonFor(file.id)?.querySelector(".file-icon");
    const to = $(`.finder-side li[data-place="${placePath}"]`, stage);
    if (to) {
      to.classList.add("flash");
      setTimeout(() => to.classList.remove("flash"), 600);
    }
    if (!from || !to || reduceMotion.matches || getComputedStyle(to.parentElement.parentElement).display === "none") return;
    const a = from.getBoundingClientRect();
    const b = to.getBoundingClientRect();
    const ghost = from.cloneNode(true);
    Object.assign(ghost.style, { position: "fixed", left: `${a.left}px`, top: `${a.top}px`, margin: 0, zIndex: 85, pointerEvents: "none" });
    document.body.append(ghost);
    ghost.animate([
      { transform: "translate(0, 0) scale(1)", opacity: 1 },
      { transform: `translate(${b.left - a.left - 16}px, ${b.top - a.top - 18}px) scale(0.3)`, opacity: 0.2 },
    ], { duration: 520, easing: "cubic-bezier(0.5, 0, 0.2, 1)" }).finished.then(() => ghost.remove());
  }

  // Actions triggered from the menu.
  const act = {
    newFile(type, target) {
      const name = uniqueName(data.untitled, type.ext);
      if (target?.kind === "folder") {
        say(format(data.toast.createdIn, { name: `${data.untitled}.${type.ext}`, dest: target.name }));
        return;
      }
      const file = { id: nextId++, name, kind: "file", ext: type.ext, hidden: false, extHidden: false };
      files.push(file);
      selectedId = file.id;
      renderFiles(file.id);
      const el = buttonFor(file.id);
      el?.classList.add("renaming");
      setTimeout(() => el?.classList.remove("renaming"), 1600);
      say(format(data.toast.created, { name }));
    },
    favorite(place) {
      const li = $(`.finder-side li[data-place="${place.path}"]`, stage);
      li?.classList.add("flash");
      setTimeout(() => li?.classList.remove("flash"), 600);
      say(format(data.toast.openedFolder, { dest: place.name }));
    },
    openApp(app, target) {
      const name = !target || (app.role === "terminal" && target.kind !== "folder") ? current.name : target.name;
      say(format(data.toast.openedApp, { app: app.title, name }));
    },
    copyCurrentPath() { copyText(data.folder); },
    cut(target) {
      cutId = target.id;
      renderFiles();
      say(format(data.toast.cut, { name: target.name }));
    },
    send(target, place, move) {
      if (place.path === data.folder) {
        if (move) { say(format(data.toast.sameFolder, { name: target.name, dest: place.name })); return; }
        const dot = target.ext ? target.name.lastIndexOf(".") : target.name.length;
        const copy = { ...target, id: nextId++, name: uniqueName(target.name.slice(0, dot), target.ext) };
        files.splice(files.indexOf(target) + 1, 0, copy);
        renderFiles(copy.id);
      } else {
        flyTo(target, place.path);
        if (move) {
          files = files.filter((file) => file !== target);
          if (selectedId === target.id) selectedId = null;
          setTimeout(() => renderFiles(), reduceMotion.matches ? 0 : 260);
        }
      }
      say(format(move ? data.toast.movedTo : data.toast.copiedTo, { name: target.name, dest: place.name }));
    },
    tool(tool, target) {
      switch (tool.id) {
        case "copyPath": return copyText(`${data.folder}/${target.name}`);
        case "copyName": return copyText(displayName(target));
        case "hideSelected":
          target.hidden = !target.hidden;
          renderFiles();
          return say(format(target.hidden ? data.toast.hidden : data.toast.shown, { name: target.name }));
        case "hideExtension":
          target.extHidden = !target.extHidden;
          return renderFiles();
        case "newFolderFromName": {
          const base = target.name.slice(0, target.name.lastIndexOf("."));
          const name = uniqueName(base, "", files.filter((file) => file !== target).map((file) => file.name));
          const folder = { id: nextId++, name, kind: "folder", hidden: false, extHidden: false };
          files.splice(files.indexOf(target), 1, folder);
          selectedId = folder.id;
          renderFiles(folder.id);
          return say(format(data.toast.newFolder, { dest: name, name: target.name }));
        }
        case "dissolve":
          files = files.filter((file) => file !== target);
          selectedId = null;
          renderFiles();
          return say(format(data.toast.dissolved, { name: target.name }));
        case "delete": return say(data.toast.deleteDemo);
        default: return say(format(data.toast.tool, { title: tool.title.replace(/…$/, ""), desc: tool.desc }));
      }
    },
  };

  // Build the menu for the current selection, following F-061.
  function buildMenu(target) {
    const m = data.menu;
    const items = [];
    const kind = target?.kind;
    const typeRow = (type) => ({ title: type.title, real: `<span class="ric doc" style="--c:${docColors[type.ext] || "#8e8e93"}"></span>`, run: () => act.newFile(type, target) });
    const appRow = (app) => ({ title: app.title, real: app.id === "terminal" ? `<span class="ric terminal">&gt;_</span>` : `<span class="ric vscode">&lt;/&gt;</span>`, run: () => act.openApp(app, target) });
    const placeRow = (place, run) => ({ title: place.name, real: `<span class="ric folder"></span>`, run });

    if (!target || kind === "folder") items.push({ title: m.newFile, icon: "doc-plus", children: data.types.map(typeRow) });
    if (!target) items.push({ title: m.favorites, icon: "star", children: data.places.map((place) => placeRow(place, () => act.favorite(place))) });
    items.push({ title: m.openInApp, icon: "app", children: data.apps.map(appRow) });
    if (!target) items.push({ title: m.copyCurrentPath, icon: "link", run: act.copyCurrentPath });
    if (target) {
      const dest = (move) => [
        ...data.places.map((place) => placeRow(place, () => act.send(target, place, move))),
        { sep: true },
        { title: m.chooseFolder, icon: "folder-q", run: () => say(data.toast.chooseFolder) },
      ];
      items.push({ title: m.cut, icon: "scissors", run: () => act.cut(target) });
      items.push({ title: m.copyTo, icon: "folder-plus", children: dest(false) });
      items.push({ title: m.moveTo, icon: "folder-arrow", children: dest(true) });
      const tools = [];
      toolGroups.forEach((group) => {
        const rows = group.filter((tool) => tool.for.includes(kind)).map((tool) => {
          let title = tool.title;
          if (tool.id === "hideSelected" && target.hidden) title = m.showSelected;
          if (tool.id === "hideExtension" && target.extHidden) title = m.showExtension;
          return { title, run: () => act.tool(tool, target) };
        });
        if (rows.length && tools.length) tools.push({ sep: true });
        tools.push(...rows);
      });
      items.push({ title: m.toolbox, icon: "wrench", children: tools });
    }
    return items;
  }

  // Menu rendering and keyboard handling.
  let menus = [];

  function closeMenus(depth = 0) {
    menus.splice(depth).forEach((menu) => menu.el.remove());
  }

  function place(el, x, y, flipFrom) {
    const margin = 8;
    const rect = el.getBoundingClientRect();
    let left = x;
    let top = y;
    if (left + rect.width > innerWidth - margin) left = flipFrom != null ? flipFrom - rect.width : innerWidth - margin - rect.width;
    if (top + rect.height > innerHeight - margin) top = Math.max(margin, innerHeight - margin - rect.height);
    left = Math.max(margin, left);
    el.style.left = `${left}px`;
    el.style.top = `${top}px`;
    el.style.setProperty("--ox", `${x - left}px`);
    el.style.setProperty("--oy", `${y - top}px`);
  }

  function openMenu(items, x, y, depth = 0, flipFrom = null) {
    closeMenus(depth);
    const el = document.createElement("div");
    el.className = "menu";
    el.setAttribute("role", "menu");
    el.dataset.depth = depth;
    const rows = [];
    items.forEach((item) => {
      if (item.sep) { el.insertAdjacentHTML("beforeend", `<div class="msep" role="separator"></div>`); return; }
      const row = document.createElement("div");
      row.className = "mi";
      row.setAttribute("role", "menuitem");
      row.tabIndex = -1;
      if (item.children) row.setAttribute("aria-haspopup", "menu");
      const lead = item.real || (item.icon ? svg(item.icon) : "");
      row.innerHTML = `${lead}<span class="t">${escapeHTML(item.title)}</span>${item.children ? svg("chevron", "ic chev") : ""}`;
      row.addEventListener("pointerenter", () => activate(depth, rows.indexOf(entry), true));
      row.addEventListener("click", (event) => { event.stopPropagation(); choose(depth, rows.indexOf(entry)); });
      const entry = { row, item };
      rows.push(entry);
      el.append(row);
    });
    document.body.append(el);
    place(el, x, y, flipFrom);
    const menu = { el, rows, index: -1 };
    menus[depth] = menu;
    return menu;
  }

  let hoverTimer;
  function activate(depth, index, fromPointer = false) {
    const menu = menus[depth];
    if (!menu) return;
    closeMenus(depth + 1);
    menu.rows.forEach((entry, i) => entry.row.classList.toggle("active", i === index));
    menu.index = index;
    const entry = menu.rows[index];
    if (!entry) return;
    entry.row.focus({ preventScroll: true });
    clearTimeout(hoverTimer);
    if (entry.item.children && fromPointer) hoverTimer = setTimeout(() => openSub(depth, index, false), 120);
  }

  function openSub(depth, index, focusFirst) {
    const entry = menus[depth]?.rows[index];
    if (!entry?.item.children) return;
    const rect = entry.row.getBoundingClientRect();
    const menuRect = menus[depth].el.getBoundingClientRect();
    const sub = openMenu(entry.item.children, menuRect.right - 3, rect.top - 5, depth + 1, menuRect.left + 3);
    entry.row.classList.add("active");
    if (focusFirst) activate(depth + 1, 0);
    return sub;
  }

  function choose(depth, index) {
    const entry = menus[depth]?.rows[index];
    if (!entry) return;
    if (entry.item.children) { openSub(depth, index, true); return; }
    closeMenus();
    entry.item.run?.();
    returnFocus();
  }

  let focusBack = null;
  function returnFocus() {
    const target = focusBack && document.contains(focusBack) ? focusBack : content;
    target.focus({ preventScroll: true });
  }

  document.addEventListener("keydown", (event) => {
    if (!menus.length) return;
    const depth = menus.length - 1;
    const menu = menus[depth];
    const count = menu.rows.length;
    switch (event.key) {
      case "ArrowDown": activate(depth, (menu.index + 1) % count); break;
      case "ArrowUp": activate(depth, (menu.index - 1 + count) % count); break;
      case "Home": activate(depth, 0); break;
      case "End": activate(depth, count - 1); break;
      case "ArrowRight": if (menu.rows[menu.index]?.item.children) openSub(depth, menu.index, true); break;
      case "ArrowLeft":
        if (depth > 0) { closeMenus(depth); activate(depth - 1, menus[depth - 1].index); }
        break;
      case "Enter": case " ": if (menu.index >= 0) choose(depth, menu.index); break;
      case "Escape": closeMenus(); returnFocus(); break;
      case "Tab": closeMenus(); return;
      default: return;
    }
    event.preventDefault();
  });

  document.addEventListener("pointerdown", (event) => {
    if (menus.length && !event.target.closest(".menu")) closeMenus();
  });
  addEventListener("resize", () => closeMenus());
  addEventListener("scroll", () => { if (menus.length && !autoplay) closeMenus(); }, { passive: true });
  addEventListener("blur", () => closeMenus());

  function contextAt(target, x, y) {
    select(target ? target.id : null);
    focusBack = target ? buttonFor(target.id) : content;
    const menu = openMenu(buildMenu(target), x, y);
    return menu;
  }

  // Right-click inside the window. Everywhere else keeps the browser menu.
  content.addEventListener("contextmenu", (event) => {
    event.preventDefault();
    stopAutoplay();
    const el = event.target.closest(".file");
    contextAt(el ? fileById(Number(el.dataset.id)) : null, event.clientX, event.clientY);
  });

  content.addEventListener("click", (event) => {
    stopAutoplay();
    const el = event.target.closest(".file");
    select(el ? Number(el.dataset.id) : null);
  });

  // Keyboard: the context menu key or Shift+F10 on a file or the window.
  content.addEventListener("keydown", (event) => {
    if (event.key === "ContextMenu" || (event.shiftKey && event.key === "F10")) {
      event.preventDefault();
      stopAutoplay();
      const el = event.target.closest(".file");
      const rect = (el || content).getBoundingClientRect();
      contextAt(el ? fileById(Number(el.dataset.id)) : null, rect.left + rect.width / 2, rect.top + rect.height / 2);
      activate(0, 0);
    }
  });

  // Touch: long-press opens the menu.
  let press = null;
  content.addEventListener("pointerdown", (event) => {
    if (event.pointerType === "mouse") return;
    stopAutoplay();
    const el = event.target.closest(".file");
    press = { x: event.clientX, y: event.clientY, timer: setTimeout(() => {
      contextAt(el ? fileById(Number(el.dataset.id)) : null, press.x, press.y);
      press = null;
    }, 500) };
  });
  const cancelPress = (event) => {
    if (!press) return;
    if (event.type === "pointermove" && Math.hypot(event.clientX - press.x, event.clientY - press.y) < 10) return;
    clearTimeout(press.timer);
    press = null;
  };
  ["pointermove", "pointerup", "pointercancel"].forEach((type) => content.addEventListener(type, cancelPress));

  // Visible fallback for anyone without a right button.
  $("[data-open-menu]", stage).addEventListener("click", (event) => {
    stopAutoplay();
    const rect = event.currentTarget.getBoundingClientRect();
    focusBack = event.currentTarget;
    select(null);
    openMenu(buildMenu(null), rect.left, rect.bottom + 6);
    activate(0, 0);
  });

  if (matchMedia("(hover: none)").matches) {
    $("[data-hint-mouse]", stage).hidden = true;
    $("[data-hint-touch]", stage).hidden = false;
  }

  // Autoplay once: move a cursor in, right-click, New File > Markdown.
  const wait = (ms) => new Promise((resolve, reject) => {
    const timer = setTimeout(resolve, ms);
    autoplay?.signal.addEventListener("abort", () => { clearTimeout(timer); reject(new Error("stopped")); }, { once: true });
  });

  function moveCursor(x, y, duration) {
    cursor.style.transition = duration ? `transform ${duration}ms cubic-bezier(0.45, 0, 0.2, 1), opacity 0.3s ease` : "opacity 0.3s ease";
    cursor.style.setProperty("--pos", `translate(${x}px, ${y}px)`);
    cursor.style.transform = `translate(${x}px, ${y}px)`;
  }

  function stopAutoplay() {
    interacted = true;
    if (!autoplay) return;
    autoplay.abort();
    autoplay = null;
    cursor.classList.remove("on");
  }

  async function runAutoplay() {
    if (interacted) return;
    autoplay = new AbortController();
    const box = content.getBoundingClientRect();
    if (box.bottom < 0 || box.top > innerHeight) { autoplay = null; return; }
    try {
      const x = box.left + box.width * 0.72;
      const y = box.top + box.height * 0.62;
      moveCursor(box.right + 60, box.bottom + 40, 0);
      await wait(50);
      cursor.classList.add("on");
      moveCursor(x, y, 900);
      await wait(1000);
      cursor.classList.remove("click");
      void cursor.offsetWidth;
      cursor.classList.add("click");
      contextAt(null, x, y);
      await wait(500);
      activate(0, 0);
      const first = menus[0].rows[0].row.getBoundingClientRect();
      moveCursor(first.left + 60, first.top + 13, 400);
      await wait(450);
      openSub(0, 0, false);
      await wait(350);
      const md = menus[1].rows.findIndex((entry) => entry.item.title === data.types[1].title);
      const target = menus[1].rows[md].row.getBoundingClientRect();
      moveCursor(target.left + 50, target.top + 13, 450);
      await wait(250);
      activate(1, md);
      await wait(500);
      cursor.classList.remove("click");
      void cursor.offsetWidth;
      cursor.classList.add("click");
      await wait(150);
      choose(1, md);
      content.blur();
      await wait(900);
      cursor.classList.remove("on");
      autoplay = null;
    } catch {
      closeMenus();
    }
  }

  renderFiles();
  if (!reduceMotion.matches) {
    setTimeout(() => { if (!document.hidden && scrollY < 200) runAutoplay(); }, 1800);
  }
  ["keydown", "wheel", "touchstart", "pointerdown"].forEach((type) => addEventListener(type, () => stopAutoplay(), { passive: true }));
})();
