# Enabling the expansion in the Release build (prepared, NOT applied)

Status: **not applied.** The integration keeps the Release configuration and the Release asset script exactly as in the
1.0 / 1025 source, so a Release build of this branch is functionally the 1.0 product: the expansion entry is compiled
out (`TACTICALGO_V11` is not defined for Release) and the expansion presentation assets are excluded.
The expansion is available in Debug and in the `Beta` configuration (`TacticalGoBeta` scheme), where the flag is set.

Turning it on for a shipping build changes the release packaging and therefore needs an explicit owner decision
(App Review impact, new metadata, voice policy). When that decision is made, these are the three changes.

## 1. Release build configuration (`ios/TacticalGo.xcodeproj`, object `00000000000000000000002B`)

- remove `EXCLUDED_SOURCE_FILE_NAMES = ("PresentationLab", "slime-token-v02.png", "shadow-wolf-preview-v02.png");`
- add `SWIFT_ACTIVE_COMPILATION_CONDITIONS = TACTICALGO_V11;`

## 2. Keep the unapproved English hero voices out of Release (`scripts/package-release-assets.sh`)

The original script removes `Audio/Voice` and `Models` from the built app. The expansion adds voice files under
`PresentationLab`. Extend the script so they are removed too and verify none remain:

```sh
if [ -d "$app_resources/PresentationLab" ]; then
    find "$app_resources/PresentationLab" -type f \( -iname '*voice*' -o -name 'mage-cast-A.wav' -o -name 'mage-cast-B.wav' \) -delete
    if [ -n "$(find "$app_resources/PresentationLab" -type f \( -iname '*voice*' -o -name 'mage-cast-A.wav' -o -name 'mage-cast-B.wav' \) -print -quit)" ]; then
        echo "Unapproved voice assets remain in Release" >&2; exit 1
    fi
fi
```

The expansion sample player skips a cue whose file is absent (`players[key]` is optional and `schedule` returns
`false`), so no code path depends on the voices; this was checked by reading `PresentationSamples.schedule`.

## 3. Verify before shipping anything

- clean Release build; `scripts/check-release-readiness.py` / the archive preflight
- `find <built app>/PresentationLab -iname '*voice*'` is empty
- `swift test --package-path swift/TacticalGoCore` and the UI suites listed in `INTEGRATION_RESULT.md`
- a physical-device pass of the expansion entry, the unlock gate and a full expansion match
- bump the version / build number above anything already uploaded (1.1 builds went up to 1112)
