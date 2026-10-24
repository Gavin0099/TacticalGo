# App Review Notes — 1.1 repair candidate

Reference notes for 1.1 (1121). The exact [3,751-character plain-text payload](APP_REVIEW_NOTES_1.1_SUBMITTED.txt) was saved to App Store Connect and submitted on 2026-10-24 at 11:47 Asia/Taipei. Its saved contents, selected build 1121 and manual-release setting were read back after submission. See the [submission receipt](../../artifacts/app-review-56/submission-receipt.json). The submitted 1120 notes already disclosed the major features; this replacement adds exact navigation and access conditions.

## Reviewer-facing text

Crown Tactics (皇冠戰略) is a fantasy tabletop tactics game. The interface is Traditional Chinese. No account, sign-in, reviewer password or external activation is required. iPhone and iPad use the same gameplay, features and access policy, with layouts adapted to screen size.

Public feature walkthrough:

1. Launch the app to the hero-selection lobby. The four cards are 戰士 (warrior), 法師 (mage), 盜賊 (rogue) and 牧師 (priest). Each card lists its basic and second skill. Scroll on smaller screens to see the remaining controls.
2. 對戰模式 selects 本機雙人 (two people on this device) or 電腦對戰 (computer opponent). Choose 7×7 or 9×9 and tap 開始本機雙人對戰 / 開始電腦對戰. Black has 1 AP on its first turn; later turns have 2 AP. Skills require a summoned hero, sufficient energy, a legal target and the per-turn skill allowance. Disabled skills display the unmet condition; they are not remotely activated.
3. From the lobby, open 玩法練習 and choose any 職業 · 擴充技能 item. These public practice positions let you inspect the existing basic and second skills without first playing a full match. Practice is available to all players and does not consume the free-match allowance.
4. 魔物戰場 in the lobby offers 無魔物, 史萊姆, 暗影狼 and 雙怪. Choosing monsters selects 9×9. Surround and hunt a monster to obtain its one-use loot action; that action becomes available on the player's next turn. This is ordinary game progression, not a purchase or delayed feature switch.
5. 新手教學 opens the interactive tutorial. 戰術挑戰 opens 英雄技能入門 · 六關 or 邊境攻防 · 三關. All nine fixed-rule challenges, tutorial and practice are free. The challenge screen identifies its rules. 存局與棋譜 and 續玩擴充玩法上局 provide the applicable saved-game paths.

Access and monetization:

- The first three **completed** free-play matches are free. Starting, previewing, cancelling or resuming an unfinished match does not consume another completed-match allowance. Tutorial, practice and challenges remain free.
- 購買與恢復 is visible in the lobby from the first launch. It explains the free allowance, optional rewarded ads, permanent unlock and restore. The single non-consumable product is `com.tacticalgo.crowntactics.unlock`; StoreKit supplies its localized price. There is no subscription, paid currency or purchase of combat power.
- After the three completed matches, starting another new match opens the continuation screen. 看廣告，再玩一局 is a voluntary rewarded ad for one new match. The ad action is not offered while a free allowance/reward credit or permanent unlock already permits a new match. No ad interrupts a match. An unavailable or unfinished ad grants no reward; the earned callback grants the one-match credit. Reviewers and customers follow the same conditions.
- 恢復購買 is on the purchase screen. Purchase, restore and optional advertising require the corresponding network services. 已永久解鎖 indicates a verified permanent entitlement. Please review the non-consumable IAP with this app version.

隱私與支援 in the lobby opens the policy, support and applicable ad-privacy choices. During a match, open the top-right 對戰選單 → 聲音設定 for sound preferences and Reduce Motion. The release has no English hero-voice recordings or 3D research assets. The repaired build excludes internal fixture, presentation and rules-comparison tools from Release compilation; the four public heroes, skills, monsters and other features above remain present.

## Optional reviewer attachment: quickly reach the ad-choice screen

This uses the normal local two-player game and the published rules, without a special account, launch argument, test ledger or purchase.

Start a 7×7 本機雙人 game with no monsters and default heroes. As Black, place D3 and confirm. As White, end the turn. As Black, place C2 and confirm, then E2 and confirm. As White, end the turn. As Black, place D1 and confirm to surround White's D2 commander. After the result, return to hero selection. Repeat for three completed games; the free counter becomes 0/3. Starting the next game shows the voluntary ad and purchase choices.

Developer evidence: this public route passed on the 1.1 (1121) Release iPhone and iPad simulators with no app launch arguments. This verifies navigation and existing allowance conditions; it does not claim a purchase transaction or delivered ad.
