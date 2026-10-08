# VIS-FEEL-01 審查交付

結果：完成離線靜態／動態比較稿與 `tacticalgo-game-feel` Skill 草稿，供 Owner 審查；沒有 commit、push 或 merge。
原因：使用既有 A 棋盤符號＋B 人物卡，在同一局面分離選取、魔法之手與提子回饋；不需要重畫角色或改遊戲程式。
下一步：本輪依 Owner 審查結案，經 PR code review 通過後合併保存；暫不啟動完整 2.5D 人物動畫或新的美術 Slice。

首行的 Git 狀態記錄初次交付時點。後續 Owner 已接受本輪比較工具、三職業分鏡與 Skill 設計方向，另授權 commit／push／PR 與審查通過後合併；正式素材與實機 Gate 仍未通過。

## 本輪內容

- 六張現有素材逐位元複製：A 戰士／法師 v01、A 盜賊 v02、B 三職業 v02。沿用上輪較明亮的膚色與單短刃盜賊，不生成新人物。
- 7×7／390 CSS px、9×9／320 CSS px；靜態／動態同一 fixture，同步操作。我方可選三職業，技能場景固定法師，黑方為盜賊。
- 選取環和人物卡、魔法之手起點／方向／目的地預覽與確認、成功提子和新空點提示。取消預覽不移子、不扣資源。
- 減少動態尊重系統設定，也可手動開啟；保留同樣資訊與終態。另附灰階比較。
- `REVIEW.html` 素材與程式內嵌，無網路依賴。`qa/FEEDBACK_DEMO.webm` 展示實際 Browser 動態；18 張操作截圖包含六張暫停在半段的動態畫面，另附動畫分鏡概覽圖。
- 已依 Owner 追加《皇室戰爭》參考，提供 `ANIMATION_DIRECTION.md` 和離線 `ANIMATION_STORYBOARD.html`：戰士築壘、法師魔法之手、盜賊換位各四階段。這是設計草案，尚未製作三技能完整動畫或完整 2.5D 主畫面。

法師預設已依最新 Owner 指示改為魔法之手。唯讀核對 R1 的有效本機文件，目標是雙方普通士兵、曼哈頓距離 ≤2、正交推一格至空點、保留歸屬，法師不移動。本例只展示向下推黑方普通士兵，不是完整選方向／規則驗證器。原位成為新空點，不把被推兵直接演成死亡。

## 驗證

`qa/review.json`：21 個限定的 Browser 工具檢查通過，頁面錯誤 0、HTTP 請求 0。涵蓋兩種尺寸、三職業選取、預覽／取消、推動與提子終態、重設中斷、系統／手動減少動態、鍵盤選取、手機寬度與提示下的命中區。用手寫幾何與結果條件檢查，不以動畫定義規則結果。

| 呈現方式 | 棋盤／畫面 | 實測點距 | Token 顯示寬度 |
| --- | --- | --- | --- |
| 桌面內手機框 | 7×7／390 | 51.33 px | 38.73 px |
| 桌面內手機框 | 9×9／320 | 29.75 px | 22.44 px |
| 390 px 視窗 | 7×7／390 | 51.67 px | 38.95 px |
| 320 px 視窗 | 9×9／320 | 30.00 px | 22.63 px |

視窗版移除手機框左右邊線，因此尺寸略有差異。已目視檢查完整畫面、手機畫面、推動／提子動態畫面：關鍵圖形仍在前景，沒有持續粒子或相機震動。這是設計審查，沒有真人辨識率或觸控成功率。

Skill 的官方 `quick_validate.py` 檢查通過（Windows 以 `python -X utf8` 執行）。檢查了觸發範圍、引用檔案、預览／確認邊界與現有角色 Skill 的分工；沒有安裝這份草稿，也沒有獨立真人效益驗證。

重跑工具可用 `python qa/build-review.py`，再以現有 Node／Playwright 與 `VIS_FEEL_CHROME` 執行 `node qa/check-review.cjs`。短錄影工具為 `qa/record-feedback.cjs`。檢查依賴不隨包安裝，離線比較頁本身不需要這些工具。

## 方法與來源

取用 [OpenAI Game UI Frontend](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/skills/game-ui-frontend/SKILL.md) 的棋盤保護和克制動態方法，以及 [Game Playtest](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/skills/game-playtest/SKILL.md) 的代表狀態操作／截圖審查方式。[Sprite Pipeline](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/skills/sprite-pipeline/SKILL.md) 的一致比例與 anchor 方法保留供未來影格製作，本輪不生成 sprite。這是針對 TacticalGo 的應用判斷，不是這些來源證明本遊戲更好玩。

公開來源固定 commit、內容 hash 與 R1 有效檔案 hash 在 `sources/`。R1 文件當時有未提交修改，記錄有效檔案 SHA-256，不以 HEAD 代表全部內容。素材來源及上輪生成紀錄保留在 `provenance.json` 和 `sources/asset-provenance.json`；其原始圖路徑屬上輪包，並未假裝全部包含於本包。

## Gate 與範圍

| 項目 | 狀態 |
| --- | --- |
| 比較工具 QA | 通過限定檢查 |
| Owner 比較工具／分鏡審查 | 接受本輪交付及設計草案；正式美術未核准 |
| 素材正式發布／權利確認 | 未升格／待確認 |
| 真人辨識、實體 iPhone 觸控 | 未執行；不阻擋本次交付 |
| 正式遊戲 UI 與 Domain 事件整合 | 未執行 |
| 魔法之手策略價值／平衡／好玩 | 本包未驗證 |
| G0／G1 | G0 保持 Pending；G1 不提前 |
| Skill | 草稿，未安裝 |

寫入限於 Visual worktree 的本輪候選與 `docs/visual/`。未修改 Gameplay、Domain、BoardView、Windows UI、KCK；沒有動畫影格生成或新職業。舊交付包保留。動態時間是可調提案，約 23 px 棋子與約 30 px 點距的限制仍存在，CSS px 不直接等於 iOS pt。

保留木質厚邊、柔和投影、固定近俯視鏡頭、英雄底座和棋盤下方人物卡的方向供未來整合參考。Owner 決定本輪到此結案，優先完成 Gameplay 的既定 Gate；本輪不開完整 2.5D 製作。選取環、施法準備、提子後生存空格提示的有限修正，留待正式整合範圍另行處理。
