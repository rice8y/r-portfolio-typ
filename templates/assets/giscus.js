function updateGiscusTheme() {
  const theme = document.documentElement.classList.contains("dark") ? "dark" : "light";
  const iframe = document.querySelector("iframe.giscus-frame");
  if (!iframe) return;
  iframe.contentWindow.postMessage({ giscus: { setConfig: { theme } } }, "https://giscus.app");
}
const giscusObserver = new MutationObserver(updateGiscusTheme);
giscusObserver.observe(document.documentElement, { attributes: true, attributeFilter: ["class"] });
window.addEventListener("message", (event) => {
  if (event.origin === "https://giscus.app") updateGiscusTheme();
});


// Giscus creates its iframe asynchronously. Retry a few times so the initial
// light/dark theme is corrected even when the iframe appears after this script.
let giscusThemeRetryCount = 0;
const giscusThemeRetry = setInterval(() => {
  updateGiscusTheme();
  giscusThemeRetryCount += 1;
  if (giscusThemeRetryCount > 40 || document.querySelector("iframe.giscus-frame")) {
    clearInterval(giscusThemeRetry);
  }
}, 250);
