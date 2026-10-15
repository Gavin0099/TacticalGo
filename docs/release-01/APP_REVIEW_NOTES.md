# 1.0 App Review notes — draft

This text is prepared locally and has not been saved in App Store Connect. Recheck against the final signed 1.0 build before copying. The review contact telephone number is still required from the owner. No reviewer login is required.

## Proposed reviewer-facing text

Crown Tactics (皇冠戰略) is a fantasy tabletop tactics game with a Traditional Chinese interface. There is no game account or sign-in. The goal is to protect your commander and capture the opponent's commander by removing all liberties from its connected group.

Start from 開始對戰 (Start Match), 新手入門 (Tutorial), or 戰術挑戰 (Challenges). The tutorial and all nine challenges remain available without a purchase. Challenges use fixed original-rule positions and display that rule set; new free-play matches use the adopted expanded warrior/mage skills.

The app is free to download. The first three completed free-play matches are free. An unfinished saved match can still be resumed and finished. After the allowance is exhausted, the player may choose either:

- 皇冠戰略完整解鎖: a single non-consumable purchase for permanent access without advertisements; no subscription, consumable currency, or combat advantage.
- 看廣告開一局: voluntarily watch one rewarded advertisement for one additional new match. The reward is granted only through the advertising SDK's earned-reward callback. Closing early does not grant a match. No advertisements interrupt an ongoing match.

The purchase screen contains 恢復購買 (Restore Purchases). StoreKit supplies the displayed price. Purchase, restore, and optional advertising require network access; the app explains failures and does not fabricate an advertisement or reward when an ad is unavailable. Players can return to the home screen and continue using tutorials/challenges. Offline gameplay is available for already permitted or started matches, subject to a previously verified entitlement.

Support, privacy policy, and advertising privacy choices are accessible from the home tools menu. Sound settings include separate music/effects controls and Reduce Motion. Unapproved English hero voices and 3D research assets are excluded from the release configuration.

## Before this text is submitted

- Confirm the exact final review-contact data with the owner; do not copy private data from another app.
- Verify the final signed build, actual StoreKit Sandbox purchase/restore, third free match completion, earned/non-earned rewarded outcomes, and public support/privacy URLs.
- Use a screenshot of the actual final purchase interface for IAP review. Debug StoreKit prices and screenshots are development evidence, not the final production interface.
- Attach the first non-consumable IAP to the 1.0 submission once all required product metadata is complete.
- Keep manual release selected. This document does not claim submission, approval, or publication.
