# 音訊逐檔量測前後表

此表的改善是技術規格/事件區隔判讀，主觀聽感全部未檢查。LUFS採ffmpeg EBU R128，短於400ms補靜音至400ms（原始時長與補長值分開保留）；同組差異以相同方法比較。所有原始ffmpeg輸出、頻譜質心、三段能量比、PCM首尾差、峰值及削波數在各stage/metrics.json及*-ebur128.txt。

| cue | 前/後 LUFS | 前/後峰值 dBFS | 前/後時長 s | 判定與波形證據 |
|---|---|---|---|---|
| b-danger | -32.9 / -32.9 | -20.44 / -20.44 | 76.8 / 76.8 | 持平（位元相同）；聽感未檢查；[波形](after/b-danger-waveform.png) |
| b-defeat | -21.5 / -21.5 | -14.39 / -14.39 | 6.0 / 6.0 | 持平（位元相同）；聽感未檢查；[波形](after/b-defeat-waveform.png) |
| b-focus | -37.1 / -37.1 | -25.09 / -25.09 | 76.8 / 76.8 | 持平（位元相同）；聽感未檢查；[波形](after/b-focus-waveform.png) |
| b-normal | -21.0 / -21.0 | -9.12 / -9.12 | 76.8 / 76.8 | 持平（位元相同）；聽感未檢查；[波形](after/b-normal-waveform.png) |
| b-victory | -21.0 / -21.0 | -14.21 / -14.21 | 6.0 / 6.0 | 持平（位元相同）；聽感未檢查；[波形](after/b-victory-waveform.png) |
| capture | -14.7 / -21.0 | -5.68 / -6.25 | 0.48 / 0.7 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/capture.png) |
| commander-capture | N/A / -22.0 | N/A / -7.17 | N/A / 1.08 | 新增，無對應before；原生路由另驗；聽感未檢查；[波形](comparisons/commander-capture.png) |
| confirm | N/A / -27.0 | N/A / -16.59 | N/A / 0.32 | 新增，無對應before；原生路由另驗；聽感未檢查；[波形](comparisons/confirm.png) |
| danger | -11.2 / -23.0 | -5.68 / -9.12 | 0.55 / 0.65 | 未檢查（警示效果）；已降低過突出的基線音量；[波形](comparisons/danger.png) |
| defeat | -14.4 / -22.0 | -5.68 / -14.17 | 1.55 / 1.18 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/defeat.png) |
| draw | -15.1 / -22.0 | -5.68 / -12.9 | 1.2 / 1.1 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/draw.png) |
| mage | -16.1 / -22.0 | -5.68 / -11.51 | 0.62 / 0.9 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/mage.png) |
| place | -14.9 / -21.0 | -5.68 / -6.0 | 0.24 / 0.48 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/place.png) |
| rogue | -16.7 / -22.0 | -5.68 / -8.72 | 0.35 / 0.55 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/rogue.png) |
| selection | -27.0 / -27.0 | -17.72 / -12.18 | 0.11 / 0.18 | 持平（目標響度不變）；音色差異未聽驗；[波形](comparisons/selection.png) |
| summon | -14.1 / -22.0 | -5.68 / -11.33 | 0.72 / 0.98 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/summon.png) |
| tabletop-loop | -20.8 / -20.8 | -9.37 / -9.37 | 21.333333 / 21.333333 | 持平（位元相同）；聽感未檢查；[波形](after/tabletop-loop-waveform.png) |
| victory | -16.9 / -22.0 | -5.68 / -14.2 | 2.15 / 1.18 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/victory.png) |
| warrior | -16.2 / -22.0 | -5.68 / -4.72 | 0.45 / 0.85 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/warrior.png) |
| p3-air | -36.9 / -36.9 | -19.99 / -19.99 | 0.22 / 0.22 | 持平（位元相同）；聽感未檢查；[波形](after/p3-air-waveform.png) |
| p4-conjure | -20.1 / -20.1 | -7.68 / -7.68 | 0.38 / 0.38 | 持平（位元相同）；聽感未檢查；[波形](after/p4-conjure-waveform.png) |
| p4-contact | -23.1 / -23.1 | -2.93 / -2.93 | 0.22 / 0.22 | 持平（位元相同）；聽感未檢查；[波形](after/p4-contact-waveform.png) |
| p4-push | -20.2 / -20.2 | -5.62 / -5.62 | 0.26 / 0.26 | 持平（位元相同）；聽感未檢查；[波形](after/p4-push-waveform.png) |
| p5-conjure | -17.5 / -23.0 | -4.75 / -10.61 | 0.395011 / 0.72 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/p5-conjure.png) |
| p5-contact | -17.1 / -23.0 | -2.16 / -13.03 | 0.368005 / 0.82 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/p5-contact.png) |
| p5-push | -17.5 / -23.0 | -5.34 / -12.51 | 0.26 / 0.68 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/p5-push.png) |
| w7-brace | -25.6 / -23.0 | -4.86 / -6.23 | 0.2 / 0.55 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/w7-brace.png) |
| w7-land | -25.1 / -23.0 | -4.9 / -8.23 | 0.24 / 0.5 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/w7-land.png) |
| w7-strike | -18.8 / -23.0 | -2.97 / -5.39 | 0.33 / 0.8 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/w7-strike.png) |
| p8-priest-bless | -23.8 / -23.0 | -10.24 / -13.57 | 0.42 / 0.95 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/p8-priest-bless.png) |
| p8-priest-land | -27.7 / -23.0 | -7.73 / -10.76 | 0.22 / 0.7 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/p8-priest-land.png) |
| p8-priest-prayer | -24.5 / -23.0 | -7.62 / -11.24 | 0.25 / 0.72 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/p8-priest-prayer.png) |
| p8-rogue-coil | -24.2 / -23.0 | -5.73 / -14.0 | 0.24 / 0.45 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/p8-rogue-coil.png) |
| p8-rogue-dash | -24.5 / -23.0 | -2.58 / -11.67 | 0.2 / 0.42 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/p8-rogue-dash.png) |
| p8-rogue-land | -26.9 / -23.0 | -5.96 / -8.95 | 0.2 / 0.48 | 改善（短音效規格/事件包絡）；聽感未檢查；[波形](comparisons/p8-rogue-land.png) |
| p8-slime-bounce | -26.4 / -26.4 | -2.16 / -2.16 | 0.26 / 0.26 | 持平（位元相同）；聽感未檢查；[波形](after/p8-slime-bounce-waveform.png) |
| p8-slime-coil | -26.6 / -26.6 | -2.16 / -2.16 | 0.24 / 0.24 | 持平（位元相同）；聽感未檢查；[波形](after/p8-slime-coil-waveform.png) |
| p8-slime-land | -27.7 / -27.7 | -2.16 / -2.16 | 0.22 / 0.22 | 持平（位元相同）；聽感未檢查；[波形](after/p8-slime-land-waveform.png) |
| p8-wolf-dash | -27.2 / -27.2 | -7.19 / -7.19 | 0.2 / 0.2 | 持平（位元相同）；聽感未檢查；[波形](after/p8-wolf-dash-waveform.png) |
| p8-wolf-growl | -23.9 / -23.9 | -7.42 / -7.42 | 0.52 / 0.52 | 持平（位元相同）；聽感未檢查；[波形](after/p8-wolf-growl-waveform.png) |
| p8-wolf-land | -26.9 / -26.9 | -5.96 / -5.96 | 0.2 / 0.2 | 持平（位元相同）；聽感未檢查；[波形](after/p8-wolf-land-waveform.png) |
| p-capture | -22.5 / -22.5 | -5.92 / -5.92 | 0.18 / 0.18 | 持平（位元相同）；聽感未檢查；[波形](after/p-capture-waveform.png) |
| p-charge | -23.7 / -23.7 | -7.55 / -7.55 | 0.2 / 0.2 | 持平（位元相同）；聽感未檢查；[波形](after/p-charge-waveform.png) |
| p-land | -24.7 / -24.7 | -5.19 / -5.19 | 0.18 / 0.18 | 持平（位元相同）；聽感未檢查；[波形](after/p-land-waveform.png) |
| p-release | -18.1 / -18.1 | -7.89 / -7.89 | 0.3 / 0.3 | 持平（位元相同）；聽感未檢查；[波形](after/p-release-waveform.png) |
