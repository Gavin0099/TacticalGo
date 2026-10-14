# 研究來源與可借用的方法

查證日期：2026-10-13。以下摘要由本專案撰寫，沒有安裝外部 skill、執行下載的程式或複製遊戲資產。repo 用固定 commit；官方文章／圖片用實際來源 URL。之後採用 code 或素材時再核對需要的授權與版本。

## 品質標竿與畫面參考

### Hearthstone：事件節奏、聲音層次與職業身份

- [官方聲音團隊訪談](https://news.blizzard.com/en-us/article/23964694/inside-battle-net-meet-the-sound-team-behind-hearthstones-harmonic-design)：已讀全文。團隊說明回合制的固定節奏、施法與接觸的關鍵拍點、情緒音色，以及避免太多聲音同時出現。用於 cue 分工與混音假設；沒有在本次試聽文章中的音訊，不能據此宣稱候選音色已相當。
- [官方 VFX 製作文章](https://hearthstone.blizzard.com/en-us/news/22552047)：已讀文章。特效要幫玩家讀懂盤面，以顏色、形狀及材質維持職業身份。用於可讀性與職業語彙；不是所有演出都應更大、更亮。
- [2019 Battlegrounds 官方介紹](https://hearthstone.blizzard.com/en-gb/news/23156373/introducing-hearthstone-battlegrounds)：已看 [Recruit 徽章](https://bnetcmsus-a.akamaihd.net/cms/gallery/BR79KB59JRS21572367737589.jpg) 與 [Combat 徽章](https://bnetcmsus-a.akamaihd.net/cms/gallery/1DZML2G2NP9Y1572367736483.jpg)。前者木桶／金幣／紫布，後者刀刃／深色金屬；粗亮標題與暗輪廓、集中亮點構成階段差異。這是靜態材質／階層參考，不代表 2026 全部 UI，也不支持動畫時長。

### Demeo x Dungeons & Dragons: Battlemarked：完整桌上戰場

[官方 media kit](https://www.resolutiongames.com/media-kit-battlemarked)。實際看過：

- [Ambush_01](https://images.squarespace-cdn.com/content/v1/61813b3361b99650be1a2c4c/1763110339354-SCJVMRSBWDOTOUH0UG0W/Ambush_01.webp)：中央路面低雜訊、邊緣森林較暗；底座及接觸陰影建立微縮尺度；局部青色選取和描邊範圍；人物、回合與能力盤各有區域。
- [GoblinStorage_01](https://images.squarespace-cdn.com/content/v1/61813b3361b99650be1a2c4c/1763110360139-3GHCL9WGZAGGOF0IPWZ5/GoblinStorage_01.webp)：木板、粗石、暖色局部光與冷背景形成材質和深度，角色輪廓由底座和背景分離。

TacticalGo 的衍生方向是「裝飾向外、戰局中心清楚、材質分工與接觸陰影」。不搬角色、地圖或卡牌規則，不把橫向／VR 介面比例直接套在手機。

### Demeo：卡片、棋盤與手工物件

- [官方美術訪談](https://www.resolutiongames.com/blog/how-the-demeo-team-created-a-masterpiece)：已讀，說明實體卡片、棋盤、標籤與手工模型方向。
- [官方 media kit](https://www.resolutiongames.com/media-kit-demeo)：實際看過 [Cards](https://images.squarespace-cdn.com/content/v1/61813b3361b99650be1a2c4c/1760093449176-8GAY7SORTEOLBVNK7C1L/Demeo%2B-%2BRealm%2Bof%2BRat%2BKing%2B-%2BCards%2BScreenshot.webp) 的框架／插畫／資訊區，以及 [Miss](https://images.squarespace-cdn.com/content/v1/61813b3361b99650be1a2c4c/1760093458778-RZ3OKDMGZBL32E03IXFU/Demeo%2BMiss.webp) 的底座、粗輪廓與單一事件焦點。

這些是靜態觀察，未看完整動畫或聽音。官方 Solasta 頁也曾搜尋，但原圖取用失敗，沒有納入已看過的證據。

## 可重用 repo／skill 方法

### OpenAI Game Studio

查證 commit `0722921d5542fc593105c27bd52630babd8b8c2a`，plugin version 0.1.2。

- [game-ui-frontend](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/skills/game-ui-frontend/SKILL.md)：固定材質、色盤、文字與動態語氣，保護遊戲焦點。
- [game-playtest](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/skills/game-playtest/SKILL.md)：實際操作主要動作、截取狀態並分別檢查 UI 與呈現。
- [sprite-pipeline](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/skills/sprite-pipeline/SKILL.md)：核定 seed frame、固定 scale／anchor／alpha，查看實際尺寸。只有需要 sprite 的任務才使用，不強制每個 UI 變化生成影格。

[plugin manifest](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/.codex-plugin/plugin.json) 宣告 MIT；本次未在 repo root 或 game-studio 目錄找到 LICENSE 文字，GitHub repo license 欄位為 null。本 skill 只以原創摘要借用方法。來源主要面向 browser／Phaser／Three.js，不代表 TacticalGo 應更換 SwiftUI 架構。

### GameSoundEngine：音訊資源重用與分組

`tkier/GameSoundEngine` @ `85ac4b2ce5806bd964aa232e67d06c61d7032e0f`（2017）。

[SoundEngine.swift](https://github.com/tkier/GameSoundEngine/blob/85ac4b2ce5806bd964aa232e67d06c61d7032e0f/SoundEngine/SoundEngine/SoundEngine.swift)、[SoundSFX.swift](https://github.com/tkier/GameSoundEngine/blob/85ac4b2ce5806bd964aa232e67d06c61d7032e0f/SoundEngine/SoundEngine/SoundSFX.swift)、[Apache-2.0 license](https://github.com/tkier/GameSoundEngine/blob/85ac4b2ce5806bd964aa232e67d06c61d7032e0f/LICENSE)。

參考預載 buffer、重用播放器、BGM／SFX 分組，以及受控 sample／音高／音量變體。舊 Swift／AVAudioSession API 未於本案編譯；不是可直接加入的現代 iOS dependency。先檢查本案既有播放器已做到哪些。

### SKTUtils：曲線與動作參數分開

`kodecocodes/SKTUtils` @ `fcd986718fb410db9555d51b4ae4e4a58b6349fc`（2016）。

[SKTEffects.swift](https://github.com/kodecocodes/SKTUtils/blob/fcd986718fb410db9555d51b4ae4e4a58b6349fc/SKTUtils/SKTEffects.swift)、[timing functions](https://github.com/kodecocodes/SKTUtils/blob/fcd986718fb410db9555d51b4ae4e4a58b6349fc/SKTUtils/SKTTimingFunctions.swift)、[MIT license](https://github.com/kodecocodes/SKTUtils/blob/fcd986718fb410db9555d51b4ae4e4a58b6349fc/LICENSE.txt)。

借用時間曲線和位移／縮放／旋轉分離、以相對差量組合動作的做法；按具體事件選擇回彈或減速。舊 Swift 原始碼與 README 的歷史 API 限制不當作目前平台事實，不為加曲線而先換 renderer。

### Game Feel Flow：同一事件共用時間軸

`kezhihao/godot-game-feel-flow` @ `1739f89d268cdd8aa23f8804d9d1afd53d4869de`。

[combo entry](https://github.com/kezhihao/godot-game-feel-flow/blob/1739f89d268cdd8aa23f8804d9d1afd53d4869de/addons/game_feel_flow/core/gff_combo_entry.gd)、[combo](https://github.com/kezhihao/godot-game-feel-flow/blob/1739f89d268cdd8aa23f8804d9d1afd53d4869de/addons/game_feel_flow/core/gff_combo.gd)、[sequencer](https://github.com/kezhihao/godot-game-feel-flow/blob/1739f89d268cdd8aa23f8804d9d1afd53d4869de/addons/game_feel_flow/core/sequencer/gff_sequencer.gd)、[MIT license](https://github.com/kezhihao/godot-game-feel-flow/blob/1739f89d268cdd8aa23f8804d9d1afd53d4869de/LICENSE)。

借用 event start／duration／track／intensity 及 pause／stop／seek 的顯式表示，讓音效、位移、閃光依同一事件時間設計。這是 Godot／GDScript repo，不是 Swift 套件；已查版本的 combo intensity curve 只取 midpoint，不能把它宣稱成完整逐幀曲線方案。

## 平台與工作流程文件

- [Apple: Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)：需要加入震動時才讀。以事件和視聽一致為準，提供可停用的控制，不用震動補償看不懂的操作。
- [Apple: Getting Started with Actions](https://developer.apple.com/documentation/spritekit/getting-started-with-actions)：若用 SpriteKit，注意提前移除 action 不會執行原本的 completion；清理和規則不能只綁在 completion。
- [OpenAI: Using Goals in Codex](https://developers.openai.com/cookbook/examples/codex/using_goals_in_codex)：持續工作需要明確完成條件、驗證和停止條件。只在使用者要求持續 Goal 時使用；本 skill 不自行建立。

## 本專案沿革

本 skill 延伸 `assets/candidates/vis-feel-01/skill-draft/tacticalgo-game-feel/` 的 2026-10-08 草稿。舊版重點是 A Token／B 卡的離線回饋比較；2026-10-13 Owner 擴大目標為完整畫面、動畫與聲音對標 Hearthstone。舊草稿保留歷史用途，不作本版本的執行入口。

現行人物身份仍以真正存在的素材和最新 Owner 指示為準；`.agents/skills/tacticalgo-character-style/` 提供人物生成方法。舊版 Clash Royale 形體參考可作輔助，但不取代新的 Hearthstone 品質目標。
