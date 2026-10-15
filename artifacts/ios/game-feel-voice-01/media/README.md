# Native recording evidence

All video pixels come from real SwiftUI running on the iPhone Simulator, with XCTest taps and Domain-confirmed actions. `native-hero-game-feel-demo.mp4` is seven receipt windows (23.1 s). `ordinary/native-hero-game-feel-demo.mp4` is normal placement capturing a commander. Each frame carries the audio/source boundary.

**Audio is event-timed postmix, not device/system capture.** `game-feel-audio-trace.json` records the actual visible GameStore audio owner's key, uptime, successful player start, player volume and stops. `compose-event-demo.py` mixes the original current V3 WAVs and original AUDIO-01 SFX at those times, respects stops, checks mix peaks and uses a caption overlay. It does not infer successful capture from images. Receipt before/after/resources/events are in `game-feel-receipts.json` and `demo-edit-audit.json`.

Native capture ready acknowledgement is the time zero; no hardware audio latency or synchronization precision is claimed. BGM is off in these clips (formal integration HOLD). Human listening Pending.

`record-ui-walkthrough.py` / `ordinary/record-ordinary.py`: build-for-testing the current iOS project first, then run against the local Simulator identifier defined in the script. They retain raw silent.mov and .xcresult locally, copy actual app documents and assert test/recorder success. The scripts refuse to overwrite an existing capture. `compose-event-demo.py` needs FFmpeg plus Python Pillow/numpy. Run with `--ordinary` for the second capture. Models/runtimes/build products/raw 46 MB video are not checked in; rerun native capture to reproduce pixels.

Tests: main film 1/0 and ordinary film 1/0; logs are retained beside the scripts. Three pair MP3s contain exactly the six V3 clips separated by 0.6 s silence. Manifest and attribution are in `ios/TacticalGo/Audio/Voice`; all source clips remain replaceable, not final acting.
