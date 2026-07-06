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
      // Fall back to the legacy path below.
    }
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
  document.querySelectorAll("[data-bib-tools]").forEach((root) => {
    if (root.dataset.bibToolsReady) return;
    root.dataset.bibToolsReady = "true";

    const source = root.querySelector(".publication-bib-source");
    const copyButton = root.querySelector("[data-bib-copy]");
    const downloadButton = root.querySelector("[data-bib-download]");
    const status = root.querySelector(".publication-bib-status");
    const filename = root.dataset.bibFilename || "publications.bib";
    const bibText = () => `${source?.textContent.trim() || ""}\n`;

    const setStatus = (message) => {
      if (!status) return;
      status.textContent = message;
      window.setTimeout(() => {
        if (status.textContent === message) status.textContent = "";
      }, 1800);
    };

    copyButton?.addEventListener("click", async () => {
      const ok = await copyText(bibText());
      copyButton.textContent = ok ? "Copied" : "Failed";
      copyButton.classList.toggle("is-copied", ok);
      setStatus(ok ? "Copied to clipboard." : "Clipboard copy failed.");
      window.setTimeout(() => {
        copyButton.textContent = "Copy BibTeX";
        copyButton.classList.remove("is-copied");
      }, 1400);
    });

    downloadButton?.addEventListener("click", () => {
      const blob = new Blob([bibText()], { type: "application/x-bibtex;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      link.remove();
      URL.revokeObjectURL(url);
      setStatus("Download started.");
    });
  });
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
