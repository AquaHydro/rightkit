import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { mkdir } from 'node:fs/promises';

const require = createRequire(new URL('../../.build/appstore-screenshots/entry.cjs', import.meta.url));
const { chromium } = require('playwright');
const pageURL = new URL('./product-image.html', import.meta.url);
const root = fileURLToPath(new URL('../../docs/evidence/app-store/', import.meta.url));

const browser = await chromium.launch({ channel: 'chrome', headless: true });
try {
  for (const locale of ['zh', 'en']) {
    await mkdir(`${root}/${locale}`, { recursive: true });
    for (let slide = 1; slide <= 5; slide++) {
      const page = await browser.newPage({ viewport: { width: 2560, height: 1600 }, deviceScaleFactor: 1 });
      const url = new URL(pageURL);
      url.searchParams.set('locale', locale);
      url.searchParams.set('slide', String(slide));
      await page.goto(url.href);
      await page.evaluate(async () => {
        await document.fonts.ready;
        await Promise.all([...document.images].map(image => image.decode()));
      });
      const layout = await page.evaluate(() => {
        const heading = document.querySelector('h1');
        return {
          titleFits: heading.scrollWidth <= heading.clientWidth,
          imagesLoaded: [...document.images].every(image => image.naturalWidth > 0),
        };
      });
      if (!layout.titleFits || !layout.imagesLoaded) {
        throw new Error(`Invalid layout for ${locale} slide ${slide}: ${JSON.stringify(layout)}`);
      }
      const filename = ['new-file', 'move-to', 'open-in-app', 'toolbox', 'settings'][slide - 1];
      await page.screenshot({ path: `${root}/${locale}/${String(slide).padStart(2, '0')}-${filename}.png` });
      await page.close();
    }
  }
} finally {
  await browser.close();
}
