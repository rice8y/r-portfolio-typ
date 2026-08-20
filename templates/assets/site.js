function initPortfolio() {
  preloadTheme();
  onScroll();
  animate();
  initLanguageSwap();
  initCollapse();
  initNoCopyEmail();
  initCodeCopyButtons();
  initProjectControls();
  initPublicationBibTools();

  const backToTop = document.getElementById("back-to-top");
  backToTop?.addEventListener("click", (event) => scrollToTop(event));

  const backToPrev = document.getElementById("back-to-prev");
  backToPrev?.addEventListener("click", () => window.history.back());

  document.getElementById("light-theme-button")?.addEventListener("click", () => {
    localStorage.setItem("theme", "light");
    toggleTheme(false);
  });
  document.getElementById("dark-theme-button")?.addEventListener("click", () => {
    localStorage.setItem("theme", "dark");
    toggleTheme(true);
  });
  document.getElementById("system-theme-button")?.addEventListener("click", () => {
    localStorage.setItem("theme", "system");
    toggleTheme(window.matchMedia("(prefers-color-scheme: dark)").matches);
  });

  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", event => {
    if (localStorage.theme === "system" || !localStorage.theme) toggleTheme(event.matches);
  });

  document.addEventListener("scroll", onScroll);
}

function animate() {
  document.querySelectorAll(".animate").forEach((element, index) => {
    setTimeout(() => element.classList.add("show"), index * 150);
  });
}

function onScroll() {
  document.documentElement.classList.toggle("scrolled", window.scrollY > 0);
}

function scrollToTop(event) {
  event.preventDefault();
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function toggleTheme(dark) {
  const css = document.createElement("style");
  css.appendChild(document.createTextNode(`* { transition: none !important; }`));
  document.head.appendChild(css);
  document.documentElement.classList.toggle("dark", dark);
  updateFavicon(dark);
  updateGiscusTheme(dark);
  window.getComputedStyle(css).opacity;
  document.head.removeChild(css);
}

function updateFavicon(dark) {
  const icon = document.getElementById("site-favicon") || document.querySelector('link[rel="icon"]');
  if (!icon) return;
  icon.setAttribute("href", dark ? "/favicon-dark.svg" : "/favicon-light.svg");
}

function updateGiscusTheme(dark) {
  const theme = dark ? "dark" : "light";
  document.querySelectorAll("iframe.giscus-frame").forEach((iframe) => {
    iframe.contentWindow?.postMessage({ giscus: { setConfig: { theme } } }, "https://giscus.app");
  });
}

function preloadTheme() {
  const userTheme = localStorage.theme;
  if (userTheme === "light" || userTheme === "dark") {
    toggleTheme(userTheme === "dark");
  } else {
    toggleTheme(window.matchMedia("(prefers-color-scheme: dark)").matches);
  }
}

function initLanguageSwap() {
  const userLang = navigator.language || navigator.userLanguage || "";
  if (!userLang.startsWith("en")) return;
  const jaElement = document.querySelector(".lang-ja");
  const enElement = document.querySelector(".lang-en");
  if (jaElement && enElement) {
    jaElement.classList.replace("block", "hidden");
    enElement.classList.replace("hidden", "block");
  }
}



function initCodeCopyButtons() {
  document.querySelectorAll("article.prose pre").forEach((pre) => {
    if (pre.dataset.copyReady) return;
    pre.dataset.copyReady = "true";

    const wrapper = document.createElement("div");
    wrapper.className = "code-block";
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    const button = document.createElement("button");
    button.type = "button";
    button.className = "code-copy-button";
    button.setAttribute("aria-label", "Copy code");
    button.textContent = "Copy";
    wrapper.appendChild(button);

    button.addEventListener("click", async () => {
      const text = pre.innerText.replace(/\n$/, "");
      const ok = await copyText(text);
      button.textContent = ok ? "Copied" : "Failed";
      button.classList.toggle("is-copied", ok);
      window.setTimeout(() => {
        button.textContent = "Copy";
        button.classList.remove("is-copied");
      }, 1400);
    });
  });
}

async function copyText(text) {
  if (navigator.clipboard && window.isSecureContext) {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch (_) {
      // Fall back to legacy paths below.
    }
  }

  let eventCopied = false;
  const onCopy = (event) => {
    event.clipboardData?.setData("text/plain", text);
    event.preventDefault();
    eventCopied = true;
  };
  document.addEventListener("copy", onCopy);
  try {
    if (document.execCommand("copy") && eventCopied) return true;
  } catch (_) {
    eventCopied = false;
  } finally {
    document.removeEventListener("copy", onCopy);
  }

  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.setAttribute("readonly", "");
  textarea.style.position = "fixed";
  textarea.style.top = "-9999px";
  textarea.style.left = "-9999px";
  document.body.appendChild(textarea);
  textarea.select();
  textarea.setSelectionRange(0, textarea.value.length);
  let ok = false;
  try { ok = document.execCommand("copy"); }
  catch (_) { ok = false; }
  textarea.remove();
  return ok;
}

function projectDateValue(value) {
  const parts = String(value || "").split(/[/-]/).map(Number);
  if (parts.length < 3 || parts.some((part) => !Number.isFinite(part))) return 0;
  return parts[0] * 10000 + parts[1] * 100 + parts[2];
}

function initProjectControls() {
  const root = document.querySelector(".project-index");
  if (!root || root.dataset.controlsReady) return;
  root.dataset.controlsReady = "true";

  const filter = root.querySelector(".project-filter");
  const languageButtons = Array.from(root.querySelectorAll("[data-language-filter]"));
  const sortButtons = Array.from(root.querySelectorAll("[data-project-sort]"));
  const cards = Array.from(root.querySelectorAll("[data-project-card]"));
  const list = root.querySelector(".card-list");
  const empty = root.querySelector(".project-filter-empty");
  const params = new URLSearchParams(window.location.search);
  const originalOrder = new Map(cards.map((card, index) => [card, index]));

  const setLanguage = (language, updateUrl = true) => {
    let visible = 0;

    languageButtons.forEach((button) => {
      const active = button.dataset.languageFilter === language;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-pressed", active ? "true" : "false");
    });

    cards.forEach((card) => {
      const languages = (card.dataset.languages || "Other")
        .split("||")
        .map((value) => value.trim())
        .filter(Boolean);
      const show = language === "all" || languages.includes(language);
      const item = card.closest("li") || card;
      item.hidden = !show;
      if (show) visible += 1;
    });

    empty?.classList.toggle("hidden", visible !== 0);

    if (updateUrl) {
      const next = new URL(window.location.href);
      if (language === "all") next.searchParams.delete("language");
      else next.searchParams.set("language", language);
      window.history.replaceState({}, "", next);
    }
  };

  const setSort = (sort, updateUrl = true) => {
    sortButtons.forEach((button) => {
      const active = button.dataset.projectSort === sort;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-pressed", active ? "true" : "false");
    });

    if (list) {
      const sorted = [...cards].sort((a, b) => {
        const difference = projectDateValue(b.dataset[sort]) - projectDateValue(a.dataset[sort]);
        return difference || originalOrder.get(a) - originalOrder.get(b);
      });
      sorted.forEach((card) => list.append(card.closest("li") || card));
    }

    if (updateUrl) {
      const next = new URL(window.location.href);
      if (sort === "published") next.searchParams.delete("sort");
      else next.searchParams.set("sort", sort);
      window.history.replaceState({}, "", next);
    }
  };

  languageButtons.forEach((button) => {
    button.setAttribute("aria-pressed", button.classList.contains("is-active") ? "true" : "false");
    button.addEventListener("click", () => setLanguage(button.dataset.languageFilter || "all"));
  });

  sortButtons.forEach((button) => {
    button.addEventListener("click", () => setSort(button.dataset.projectSort || "published"));
  });

  const initialLanguage = params.get("language");
  if (filter && initialLanguage && languageButtons.some((button) => button.dataset.languageFilter === initialLanguage)) {
    setLanguage(initialLanguage, false);
  } else {
    setLanguage("all", false);
  }

  const initialSort = params.get("sort") === "updated" ? "updated" : "published";
  setSort(initialSort, false);
}

function initPublicationBibTools() {
  initPublicationCiteMenuDismissal();

  document.querySelectorAll("[data-bib-tools]").forEach((root) => {
    if (root.dataset.bibToolsReady) return;
    root.dataset.bibToolsReady = "true";

    const source = root.querySelector(".publication-bib-source");
    const entries = splitBibEntries(source?.textContent || "");
    const bibliography = nextBibliography(root);
    const items = Array.from(bibliography?.querySelectorAll("li") || []);

    items.forEach((item, index) => {
      const entry = entries[index];
      if (!entry) return;
      item.appendChild(createPublicationCiteMenu(entry));
    });
  });
}

function initPublicationCiteMenuDismissal() {
  if (document.documentElement.dataset.publicationCiteDismissReady) return;
  document.documentElement.dataset.publicationCiteDismissReady = "true";

  document.addEventListener("click", (event) => {
    if (event.target.closest?.(".publication-cite-menu")) return;
    closePublicationCiteMenus();
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closePublicationCiteMenus();
  });

  window.addEventListener("resize", updateOpenPublicationCiteMenus);
  window.addEventListener("scroll", updateOpenPublicationCiteMenus, { passive: true });
}

function closePublicationCiteMenus(except = null) {
  document.querySelectorAll(".publication-cite-menu[open]").forEach((menu) => {
    if (menu !== except) menu.removeAttribute("open");
  });
}

function updateOpenPublicationCiteMenus() {
  document.querySelectorAll(".publication-cite-menu[open]").forEach((menu) => {
    positionPublicationCiteMenu(menu);
  });
}

function positionPublicationCiteMenu(menu) {
  const panel = menu.querySelector(".publication-cite-options");
  if (!menu.open || !panel) {
    menu.classList.remove("is-above");
    return;
  }

  menu.classList.remove("is-above");
  const belowRect = panel.getBoundingClientRect();
  const footerTop = document.querySelector("footer")?.getBoundingClientRect().top ?? Number.POSITIVE_INFINITY;
  const lowerLimit = Math.min(window.innerHeight - 12, footerTop - 12);

  if (belowRect.bottom <= lowerLimit) return;

  menu.classList.add("is-above");
  const aboveRect = panel.getBoundingClientRect();
  if (aboveRect.top < 12 && belowRect.bottom <= window.innerHeight - 12) {
    menu.classList.remove("is-above");
  }
}

function nextBibliography(root) {
  let element = root.nextElementSibling;
  while (element) {
    if (element.getAttribute("role") === "doc-bibliography") return element;
    element = element.nextElementSibling;
  }
  return null;
}

function splitBibEntries(source) {
  const entries = [];
  let index = 0;

  while (index < source.length) {
    const start = source.indexOf("@", index);
    if (start === -1) break;

    const openBrace = source.indexOf("{", start);
    const openParen = source.indexOf("(", start);
    const open = openBrace === -1 ? openParen : openParen === -1 ? openBrace : Math.min(openBrace, openParen);
    if (open === -1) break;

    const openChar = source[open];
    const closeChar = openChar === "{" ? "}" : ")";
    let depth = 0;
    let end = open;

    for (; end < source.length; end += 1) {
      const char = source[end];
      if (char === openChar) depth += 1;
      else if (char === closeChar) {
        depth -= 1;
        if (depth === 0) {
          end += 1;
          break;
        }
      }
    }

    const text = source.slice(start, end).trim();
    const key = text.match(/^@\w+\s*[\{\(]\s*([^,\s]+)\s*,/)?.[1] || `citation-${entries.length + 1}`;
    if (text) entries.push({ key, text: `${text}\n` });
    index = end;
  }

  return entries;
}

let hayagrivaWasmPromise;

function loadHayagrivaWasm() {
  if (!hayagrivaWasmPromise) {
    hayagrivaWasmPromise = fetch("/wasm/hayagriva_export.wasm")
      .then(async (response) => {
        if (!response.ok) throw new Error(`failed to load Hayagriva WASM: ${response.status}`);
        const bytes = await response.arrayBuffer();
        return WebAssembly.instantiate(bytes, {});
      })
      .then((result) => result.instance.exports);
  }
  return hayagrivaWasmPromise;
}

async function bibtexToHayagrivaYaml(bibtex) {
  const exports = await loadHayagrivaWasm();
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  const input = encoder.encode(bibtex);
  const inputPtr = exports.hayagriva_alloc(input.length);
  new Uint8Array(exports.memory.buffer, inputPtr, input.length).set(input);

  let outputPtr = 0;
  try {
    outputPtr = exports.hayagriva_bibtex_to_yaml(inputPtr, input.length);
  } finally {
    exports.hayagriva_dealloc(inputPtr, input.length);
  }

  const outputLen = exports.hayagriva_last_result_len();
  const output = new Uint8Array(exports.memory.buffer, outputPtr, outputLen).slice();
  exports.hayagriva_result_free(outputPtr, outputLen);

  const text = decoder.decode(output);
  if (text.startsWith("ok\n")) return text.slice(3);
  throw new Error(text.startsWith("err\n") ? text.slice(4) : text);
}

function createPublicationCiteMenu(entry) {
  const menu = document.createElement("details");
  menu.className = "publication-cite-menu";

  const summary = document.createElement("summary");
  summary.className = "publication-cite-button";
  summary.setAttribute("aria-label", "Export citation");
  summary.title = "Export citation";
  summary.innerHTML = [
    '<svg viewBox="0 0 16 16" aria-hidden="true" focusable="false">',
    '<path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5zm-3 0A1.5 1.5 0 0 1 9.5 3V1H4a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4.5z"/>',
    '<path d="M8.646 6.646a.5.5 0 0 1 .708 0l2 2a.5.5 0 0 1 0 .708l-2 2a.5.5 0 0 1-.708-.708L10.293 9 8.646 7.354a.5.5 0 0 1 0-.708m-1.292 0a.5.5 0 0 0-.708 0l-2 2a.5.5 0 0 0 0 .708l2 2a.5.5 0 0 0 .708-.708L5.707 9l1.647-1.646a.5.5 0 0 0 0-.708"/>',
    '</svg>',
    '<span>Export</span>',
  ].join("");

  summary.addEventListener("click", () => closePublicationCiteMenus(menu));
  menu.addEventListener("toggle", () => {
    if (menu.open) {
      requestAnimationFrame(() => positionPublicationCiteMenu(menu));
    } else {
      menu.classList.remove("is-above");
    }
  });

  const options = document.createElement("span");
  options.className = "publication-cite-options";
  const hayagrivaText = () => bibtexToHayagrivaYaml(entry.text);

  const copyBibButton = createPublicationCiteOption("Copy BibTeX");
  attachPublicationCopy(copyBibButton, {
    text: entry.text,
    resetLabel: "Copy BibTeX",
    fallbackLabel: "BibTeX citation text",
    summary,
    menu,
    options,
  });

  const downloadBibButton = createPublicationCiteOption("Download .bib");
  attachPublicationDownload(downloadBibButton, {
    text: entry.text,
    filename: `${entry.key}.bib`,
    type: "application/x-bibtex;charset=utf-8",
    menu,
  });

  const copyHayagrivaButton = createPublicationCiteOption("Copy Hayagriva");
  attachPublicationCopy(copyHayagrivaButton, {
    text: hayagrivaText,
    resetLabel: "Copy Hayagriva",
    fallbackLabel: "Hayagriva YAML citation text",
    summary,
    menu,
    options,
  });

  const downloadHayagrivaButton = createPublicationCiteOption("Download .yml");
  attachPublicationDownload(downloadHayagrivaButton, {
    text: hayagrivaText,
    filename: `${entry.key}.yml`,
    type: "application/x-yaml;charset=utf-8",
    menu,
  });

  options.append(
    createPublicationCiteGroup("BibTeX", copyBibButton, downloadBibButton),
    createPublicationCiteGroup("Hayagriva", copyHayagrivaButton, downloadHayagrivaButton),
  );
  menu.append(summary, options);
  return menu;
}

function createPublicationCiteGroup(label, ...buttons) {
  const group = document.createElement("span");
  group.className = "publication-cite-group";
  group.setAttribute("role", "group");
  group.setAttribute("aria-label", `${label} export options`);

  const heading = document.createElement("span");
  heading.className = "publication-cite-heading";
  heading.textContent = label;

  group.append(heading, ...buttons);
  return group;
}

function createPublicationCiteOption(label) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "publication-cite-option";
  button.textContent = label;
  return button;
}

function attachPublicationCopy(button, { text, resetLabel, fallbackLabel, summary, menu, options }) {
  const runCopy = async (event) => {
    event.preventDefault();
    event.stopPropagation();
    if (button.dataset.copyBusy === "true") return;
    button.dataset.copyBusy = "true";
    button.focus();
    button.textContent = "Preparing";
    let ok = false;
    try {
      const resolvedText = await resolvePublicationExportText(text);
      ok = await copyText(resolvedText);
      button.textContent = ok ? "Copied" : "Select text";
      summary.classList.toggle("is-copied", ok);
      if (!ok) showManualBibCopy(options, resolvedText, fallbackLabel);
    } catch (error) {
      console.error(error);
      button.textContent = "Failed";
      summary.classList.remove("is-copied");
    } finally {
      window.setTimeout(() => {
        summary.classList.remove("is-copied");
        button.dataset.copyBusy = "false";
        button.textContent = resetLabel;
        if (ok) menu.removeAttribute("open");
      }, 1400);
    }
  };

  button.addEventListener("pointerdown", runCopy);
  button.addEventListener("click", runCopy);
}

function attachPublicationDownload(button, { text, filename, type, menu }) {
  button.addEventListener("click", async (event) => {
    event.preventDefault();
    event.stopPropagation();
    if (button.dataset.downloadBusy === "true") return;
    button.dataset.downloadBusy = "true";
    const resetLabel = button.textContent;
    button.textContent = "Preparing";
    try {
      const resolvedText = await resolvePublicationExportText(text);
      const blob = new Blob([resolvedText], { type });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      link.remove();
      URL.revokeObjectURL(url);
      menu.removeAttribute("open");
    } catch (error) {
      console.error(error);
      button.textContent = "Failed";
      window.setTimeout(() => {
        button.textContent = resetLabel;
      }, 1400);
    } finally {
      button.dataset.downloadBusy = "false";
      if (button.textContent === "Preparing") button.textContent = resetLabel;
    }
  });
}

async function resolvePublicationExportText(text) {
  return typeof text === "function" ? await text() : text;
}

function showManualBibCopy(container, text, label = "Citation text") {
  let textarea = container.querySelector(".publication-cite-fallback");
  if (!textarea) {
    textarea = document.createElement("textarea");
    textarea.className = "publication-cite-fallback";
    textarea.setAttribute("readonly", "");
    container.appendChild(textarea);
  }
  textarea.setAttribute("aria-label", label);
  textarea.value = text;
  textarea.focus();
  textarea.select();
  textarea.setSelectionRange(0, textarea.value.length);
}

function initNoCopyEmail() {
  document.querySelectorAll(".email-no-copy").forEach((element) => {
    if (element.dataset.noCopyReady) return;
    element.dataset.noCopyReady = "true";
    ["copy", "cut", "selectstart", "contextmenu", "dragstart"].forEach((type) => {
      element.addEventListener(type, (event) => event.preventDefault());
    });
  });
}

function initCollapse() {
  const trigger = document.getElementById("collapse-trigger");
  if (!trigger || typeof Matter === "undefined") return;
  if (trigger.dataset.collapseReady) return;
  trigger.dataset.collapseReady = "true";
  let isCollapsing = false;

  trigger.addEventListener("click", (e) => {
    e.preventDefault();
    if (isCollapsing) return;
    isCollapsing = true;
    trigger.style.color = "red";
    trigger.style.pointerEvents = "none";
    startCollapse();
  });

  function startCollapse() {
    const { Engine, Runner, Bodies, Composite, Body, Events } = Matter;
    const engine = Engine.create();
    const world = engine.world;
    engine.gravity.y = 1.0;

    const visualElements = Array.from(document.body.querySelectorAll("*")).filter(el => {
      if (["SCRIPT", "STYLE", "HEAD", "META", "LINK", "NOSCRIPT"].includes(el.tagName)) return false;
      if (el.closest("svg") && el.tagName !== "svg") return false;
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) return false;
      const comp = window.getComputedStyle(el);
      if (comp.visibility === "hidden" || comp.opacity === "0" || comp.display === "none") return false;
      const hasText = Array.from(el.childNodes).some(n => n.nodeType === 3 && n.nodeValue.trim() !== "");
      if (hasText) return true;
      if (el.classList.contains("email-no-copy")) return true;
      if (["IMG", "SVG", "BUTTON", "HR", "IFRAME", "CANVAS", "VIDEO"].includes(el.tagName)) return true;
      if (comp.backgroundColor !== "rgba(0, 0, 0, 0)" && comp.backgroundColor !== "transparent") return true;
      if (comp.borderWidth !== "0px" && comp.borderStyle !== "none") return true;
      if (comp.boxShadow !== "none") return true;
      return false;
    });

    const dropTargets = visualElements.filter(el => {
      let parent = el.parentElement;
      while (parent && parent !== document.body) {
        if (visualElements.includes(parent)) return false;
        parent = parent.parentElement;
      }
      return true;
    });

    const targetData = dropTargets.map(el => ({ el, rect: el.getBoundingClientRect() }));
    document.body.style.width = `${document.body.clientWidth}px`;
    document.body.style.height = `${document.body.scrollHeight}px`;
    document.body.style.overflow = "hidden";

    const bodiesData = [];
    targetData.forEach(({ el, rect }) => {
      document.body.appendChild(el);
      el.style.position = "fixed";
      el.style.left = `${rect.left}px`;
      el.style.top = `${rect.top}px`;
      el.style.width = `${rect.width}px`;
      el.style.height = `${rect.height}px`;
      el.style.boxSizing = "border-box";
      el.style.maxWidth = "none";
      el.style.maxHeight = "none";
      el.style.margin = "0";
      el.style.transition = "none";
      el.style.zIndex = "9999";
      const body = Bodies.rectangle(rect.left + rect.width / 2, rect.top + rect.height / 2, rect.width, rect.height, {
        collisionFilter: { group: -1 },
        frictionAir: 0.005 + Math.random() * 0.02,
        density: 0.001,
      });
      Body.setAngularVelocity(body, (Math.random() - 0.5) * 0.03);
      bodiesData.push({ body, el, initialLeft: rect.left, initialTop: rect.top, w: rect.width, h: rect.height });
    });

    Composite.add(world, bodiesData.map(d => d.body));
    const runner = Runner.create();
    Runner.run(runner, engine);
    Events.on(engine, "afterUpdate", () => {
      bodiesData.forEach(({ body, el, initialLeft, initialTop, w, h }) => {
        const dx = body.position.x - (initialLeft + w / 2);
        const dy = body.position.y - (initialTop + h / 2);
        el.style.transform = `translate(${dx}px, ${dy}px) rotate(${body.angle}rad)`;
      });
    });
  }
}

preloadTheme();
document.addEventListener("DOMContentLoaded", initPortfolio);
