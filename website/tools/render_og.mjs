// Renders tools/og.html to public/img/og.jpg. Requires Playwright (npm i -g playwright).
import { chromium } from "playwright";
import { fileURLToPath } from "node:url";

const here = (path) => fileURLToPath(new URL(path, import.meta.url));
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
await page.goto(`file://${here("./og.html")}`);
await page.evaluate(() => document.fonts.ready);
await page.screenshot({ path: here("../public/img/og.jpg"), type: "jpeg", quality: 86 });
await browser.close();
