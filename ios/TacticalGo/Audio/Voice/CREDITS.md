# Hero Voice prototype VO-01 v2

These six fixed lines were synthesized offline, with anonymous consistent model speaker indices per hero. They are TTS prototypes, not approved final character acting. Original TacticalGo dialogue is in manifest.json. Outputs were trimmed and peak-scaled; model SHA, config SHA, generator SHA and output SHA are retained.

Piper by OHF-Voice, GPL-3.0: https://github.com/OHF-Voice/piper1-gpl . The engine is used only on the development Mac; no Piper engine, model, Python or third-party runtime is bundled into the iOS application.

Voice model: rhasspy/piper-voices/en/en_US/libritts/high, repository declares MIT: https://huggingface.co/rhasspy/piper-voices . Model card states this model was trained from scratch on train-clean-360, rather than a Lessac fine-tune: https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/libritts/high/MODEL_CARD . The model itself is not committed or bundled.

Training data: LibriTTS by Heiga Zen, Viet Dang, Rob Clark, Yu Zhang, Ron J. Weiss, Ye Jia, Zhifeng Chen and Yonghui Wu (2019), derived from LibriSpeech/LibriVox. OpenSLR SLR60 lists CC BY 4.0: https://www.openslr.org/60/ . Attribution and license link: https://creativecommons.org/licenses/by/4.0/ . To retain a conservative reuse boundary, distribute these generated candidate files with this attribution under CC BY 4.0; this is not an assertion that the dataset license automatically governs all possible generated outputs. No endorsement by the dataset authors or speakers is implied.

The provisional macOS System Voice clips used for early local playback tests have been replaced and excluded from the pushed branch history. macOS Tahoe SLA section 2F prohibits public-sharing redistribution of System Voices: https://www.apple.com/legal/sla/docs/macOSTahoe.pdf . Historical local test results verify event wiring only; final asset playback will be rerun after replacement. Formal release quality and complete rights review remain Pending.
