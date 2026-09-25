# 视频 brief

完整要求见 `../brief.md`（已按它执行）。

- 状态：中文版成片 `renders/rightkit-intro-zh.mp4`。英文版和竖版在中文版确认后再做。
- 风格：repo，沿用官网设计。
- 范围：全量产品介绍，`plan.scope = {"versions":"0.1.1","platforms":["macos-desktop"]}`。只展示 macOS 访达里的用法。
- 规格：1920 × 1080，60fps，59.5 秒，中文，无旁白，代码原创配乐加动作音效。
- 链接：画面上不出现网址。
- 证据：`evidence/`（feature-evidence、style-audit、copy-review、component-usage、audio-selection、audio-mix）。
- 复现：`npm install`，`python3 audio/score.py`，`python3 <skill>/scripts/mix_audio.py plan.json`，`npm run build`，`FILM_CHANNEL=chrome node render.mjs --audio assets/master.wav --output renders/rightkit-intro-zh.mp4`。
