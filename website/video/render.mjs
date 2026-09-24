// Renders a video page frame by frame and encodes it with ffmpeg.
//
//   node website/video/render.mjs                      → website/video/out/sample.mp4
//   node website/video/render.mjs --fps 30 --still 6.8 → one PNG at 6.8 s, for checking a frame
//
// Needs Playwright (npm i -g playwright) and an ffmpeg with libx264 on PATH, or FFMPEG=/path/to/ffmpeg.
// VIDEO_FONT_CSS=/path/to/font.css adds a stylesheet before rendering, e.g. a CJK font on machines without PingFang.
import { chromium } from "playwright";
import { spawn } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const args = Object.fromEntries(process.argv.slice(2).join(" ").split("--").filter((a) => a.trim()).map((a) => {
  const [key, ...values] = a.trim().split(/\s+/);
  return [key, values];
}));
const name = args.page?.[0] ?? "sample";
const fps = Number(args.fps?.[0] ?? 60);
const still = args.still?.map(Number);
const here = (path) => fileURLToPath(new URL(path, import.meta.url));
const outDir = here("./out/");
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
await page.goto(`file://${here(`./${name}.html`)}`);
if (process.env.VIDEO_FONT_CSS) await page.addStyleTag({ path: process.env.VIDEO_FONT_CSS });
await page.evaluate(async () => {
  await Promise.all([...document.images].map((img) => img.decode().catch(() => {})));
  // Touch every glyph once so split CJK font files load before the first frame.
  window.renderAt(window.DURATION / 2);
  await document.fonts.ready;
});
const duration = await page.evaluate(() => window.DURATION);
const shoot = async (t) => {
  await page.evaluate((s) => window.renderAt(s), t);
  return page.screenshot({ type: "png", clip: { x: 0, y: 0, width: 1920, height: 1080 } });
};

if (still) {
  for (const t of still) {
    const path = `${outDir}${name}-${t}s.png`;
    writeFileSync(path, await shoot(t));
    console.log(path);
  }
} else {
  const output = `${outDir}${name}.mp4`;
  const ffmpeg = spawn(process.env.FFMPEG ?? "ffmpeg", [
    "-y", "-loglevel", "error", "-f", "image2pipe", "-framerate", String(fps), "-i", "-",
    "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-pix_fmt", "yuv420p", "-movflags", "+faststart", output,
  ], { stdio: ["pipe", "inherit", "inherit"] });
  const frames = Math.round(duration * fps);
  for (let i = 0; i < frames; i++) {
    const png = await shoot(i / fps);
    if (!ffmpeg.stdin.write(png)) await new Promise((resolve) => ffmpeg.stdin.once("drain", resolve));
    if (i % fps === 0) process.stdout.write(`\r${i}/${frames} frames`);
  }
  ffmpeg.stdin.end();
  await new Promise((resolve, reject) => ffmpeg.on("close", (code) => (code === 0 ? resolve() : reject(new Error(`ffmpeg exited ${code}`)))));
  console.log(`\n${output}`);
}
await browser.close();
