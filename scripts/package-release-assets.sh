#!/bin/sh
set -eu
# Strip rejected voice and unused 3D research resources from the BUILT Release app,
# preserving the original assets and Debug tools in the checkout.
if [ "${CONFIGURATION:-}" != "Release" ]; then exit 0; fi
app_resources="${TARGET_BUILD_DIR:?}/${UNLOCALIZED_RESOURCES_FOLDER_PATH:?}"
case "$app_resources" in *.app) ;; *) echo "Unexpected built app resource path" >&2; exit 1 ;; esac
rm -rf "$app_resources/Audio/Voice" "$app_resources/Audio/V30" "$app_resources/Models"
# R2 is an engineering-only rules comparison, not a public game mode.
rm -f "$app_resources/R2Positions.json"
if [ -e "$app_resources/Audio/Voice" ] || [ -e "$app_resources/Audio/V30" ] || [ -e "$app_resources/Models" ]; then
    echo "Unapproved research assets remain in Release" >&2; exit 1
fi
# The expansion's presentation pack carries English hero voices that are not approved for release; the player skips a cue
# whose file is absent, so nothing depends on them.
if [ -d "$app_resources/PresentationLab" ]; then
    find "$app_resources/PresentationLab" -type f \( -iname '*voice*' -o -name 'mage-cast-A.wav' -o -name 'mage-cast-B.wav' \) -delete
    if [ -n "$(find "$app_resources/PresentationLab" -type f \( -iname '*voice*' -o -name 'mage-cast-A.wav' -o -name 'mage-cast-B.wav' \) -print -quit)" ]; then
        echo "Unapproved voice assets remain in Release" >&2; exit 1
    fi
fi
