# Casting voice candidate provenance

Text: original TacticalGo short command `Move aside!`. Two newly generated
English takes; no real person, character voice or external recording used as a
reference speaker. Prompts, seeds, raw waveform, normalized dry waveform and
runtime/model file hashes are in manifest.json. No paid API or live phone TTS.

Qwen3-TTS VoiceDesign: https://github.com/QwenLM/Qwen3-TTS
Converted pinned model: https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit
Model revision: 5c390979e4b93af5f2932f90742ca99c7dd04687.
Original/converted source declarations: Apache-2.0. Retained Qwen license,
model cards and MLX license in source/. Local existing model hashes match the
previous pinned voice-production manifest; no new model download.

Runtime: mlx-audio0.5.8; runtime versions recorded in manifest.json.
Voice processing is edge trim and linear gain, -18dBFS RMS with -3dBFS peak
ceiling. No pitch/time warp or synthetic imitation of a known performer.
ASR uses local Whisper tiny.en without a target-text prompt; it checks words,
not acting. A/B directions are auditions, not validated emotion labels.

Supporting SFX use AUDIO-05 Kenney Impact Sounds / qubodup Sand Spell CC0;
retained source and exact processing rights records are in
assets/candidates/audio-05/manifest.json. Blizzard / WOW Sound public methods
inspired timing and mixing; none of their character voices or SFX were copied.

Preview movies reuse accepted native D footage with new audio postmix, not a
live iPhone recording. No final commercial release-rights or subjective
quality approval is asserted by this candidate manifest.
