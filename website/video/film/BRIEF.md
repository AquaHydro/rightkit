# 视频 brief

完整要求见 `../brief.md`（已按它执行）。

- 状态：中文版成片 `renders/rightkit-intro-zh.mp4`。英文版和竖版在中文版确认后再做。
- 风格：repo，沿用官网设计。
- 范围：全量产品介绍，`plan.scope = {"versions":"0.1.1","platforms":["macos-desktop"]}`。只展示 macOS 访达里的用法。
- 规格：1920 × 1080，60fps，59.5 秒，中文，无旁白，代码原创配乐加动作音效。
- 链接：画面上不出现网址。
- 证据：`evidence/`（feature-evidence、style-audit、copy-review、component-usage、audio-selection、audio-mix）。
- 复现：`npm install`，`python3 audio/score.py`，`python3 <skill>/scripts/mix_audio.py plan.json`，`npm run build`，`FILM_CHANNEL=chrome node render.mjs --audio assets/master.wav --output renders/rightkit-intro-zh.mp4`。

## v2（2026-09-26）

- 要求：`../brief-v2.md`；方向：`v2/DIRECTION.md`；时间轴：`v2/plan.json`。成片 `renders/rightkit-intro-v2-zh.mp4`，60 秒。
- 新素材：`recordings/`（真机录屏）、`ai-clips/`（Medio Gen 生成，mp4 不入库）。`v2/prep_clips.sh` 把它们裁切、遮住「共享中」标记，并转成逐帧关键帧的 `public/clips/*.mp4`。
- 复现：`npm ci`，`v2/prep_clips.sh`，`python3 v2/score.py`，`python3 <skill>/scripts/mix_audio.py v2/plan.json`，`FILM_PLAN=v2/plan.json node build.mjs`，`FILM_CHANNEL=chrome FILM_PLAN=v2/plan.json node render.mjs --audio v2/assets/master.wav --output renders/rightkit-intro-v2-zh.mp4`。视频素材需要 Google Chrome 解码 H.264。
