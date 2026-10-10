# VO-PERF-01｜兩句表演候選來源

Fixed TacticalGo dialogue: “Hold the line!” and “Off you go!”; voice/personality descriptions and performance directions authored for this pilot. Fully synthetic original character voices, no actor/game recording/voice clone reference. No paid API, original character art upload, or external inference service.

Offline model: Qwen3-TTS-12Hz-1.7B-VoiceDesign by Qwen Team / Alibaba Cloud; official repository and model declare Apache License 2.0:
- https://github.com/QwenLM/Qwen3-TTS
- https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign
- model license text retained in source/qwen-LICENSE.

MLX conversion: mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit, revision 5c390979e4b93af5f2932f90742ca99c7dd04687; converted with mlx-audio0.3.0, card declares Apache-2.0:
- https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit

Runtime: mlx-audio0.5.8 by Prince Canuma and contributors, MIT; MLX0.32.3, Python3.12, Apple Silicon Metal. Runtime freeze and source license retained. Model/runtime only in isolated /tmp development paths, not copied into iOS or Git. Inference uses HF_HUB_OFFLINE=1 after pinned weights download, no API keys. No new app engine or gameplay code.

Raw and edge-trimmed/linear-gain dry WAVs retained. No pitch/time effects, reverb, music or SFX are added to audition takes. Model/output SHA, exact instructions, seed and processing in manifest.json after generation. Seed retained, deterministic cross-process/cross-platform identity not claimed.

Prior rejected Piper V3 files may appear in explicitly labelled old-vs-new audition; their original provenance and attribution remain ios/TacticalGo/Audio/Voice/CREDITS.md and manifest.json. They are not used as voice-cloning input.

This is a listening candidate, not actor casting approval or complete commercial/personality-rights clearance. No endorsement by Qwen/MLX/model speakers implied. Model instruction support does not demonstrate that these particular lines achieve the intended performance. Owner listening Gate Pending; existing V3 performance rejection remains in effect until a replacement is accepted.

Independent word check uses offline MLX Whisper tiny.en only, revision5f4dafbb28e62a53c1b10426ff7eed36ca733bf7. MLX Whisper0.4.3 runtime is installed without its unused PyTorch dependency; direct file/waveform inference executes on MLX. pip dependency-check warning is retained; no full-environment pip-check PASS claim. Words are not used as an ASR prompt. No generated audio leaves the Mac.
