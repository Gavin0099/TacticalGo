# 3D-00｜實際參考盤點

目前 A0 與既有 2.5D 分層動畫維持。3D 只做規格，不重新製作任何模型。以下實際讀取 PNG 與 SHA，不把 provenance 中的檔名當成已找回 master。完整重複來源索引見 artifacts/autonomous-1011/reference-inventory.json；外部交付用相對路徑。

| 來源 | SHA-256 | 尺寸 | 用途 / 可編輯程度 |
|---|---|---|---|
| `assets/candidates/vis-feel-01/tokens/A-warrior-v01.png` | `66bffd664cc6935be140a523bbe071e65ff79d8c3fb3638bd13d860e5fc1e599` | 512×512 | 現行候選 PNG；raster，非分層原稿 / 非模型 |
| `ios/TacticalGo/Cozy/B-rogue-v02.png` | `528580b66d26e9b8a2cfa7e80a4ca427888e086adc8dc4f9ca6468856d5f58de` | 512×512 | 現行候選 PNG；raster，非分層原稿 / 非模型 |
| `ios/TacticalGo/Cozy/B-warrior-v02.png` | `50885855dc9faee8966558ea854f99d24bd0ffd0ed93c03bb6b87c8643d42298` | 512×512 | 現行候選 PNG；raster，非分層原稿 / 非模型 |
| `ios/TacticalGo/Cozy/B-mage-v02.png` | `6980751a325e51156e56f14b38171a435bd54f4ef7d509433e94d6e3b9061a33` | 512×512 | 現行候選 PNG；raster，非分層原稿 / 非模型 |

角色原圖512的B-warrior與原生Cozy副本SHA相同。A-warrior符號只作棋盤功能識別，不是頭部身份基準。法師/盜賊只列來源索引，不進三職3D製作。

## 原始與缺失

- `assets/candidates/vis-feel-01/sources/asset-provenance.json` 記錄 warrior master1254×1254、SHA `ef9708d37dfd2eb1ac30bc1cba0c57166d1e2d34c388c7ae19c54b7008ffff4d`，生成方式 image_gen identity_preserve、前一版參考SHA `27a287bf4d58435b5ff02e8649d12c7bea1fe8f8dd8783e3d0f0568a83ef888e`。這些是歷史metadata，沒有讀到該檔的pixels。
- 本輪核對主checkout及獨立Visual工作樹的 `vis-feel-01/originals/B-warrior-v02.png` 均不存在；盤點Visual candidates中的同名副本均512。不宣稱搜尋過整個磁碟或全雲端。master狀態：missing in inspected roots。
- B-warrior-v01 的生成前參考目前只有provenance記錄，未列為可見身份基準。
- 候選用途/權利仍依原manifest pending_confirmation；Owner選定美術方向不代替正式商用權利確認。沒有新增權利判斷。

## 已否決的技術模型（只讀盤點）

| 來源（主checkout相對） | SHA-256 | 種類 |
|---|---|---|
| `assets/candidates/warrior-identity-head-v01/source-view-512.png` | `fe73e316a86524dab828e5ef21fc5ec6c15801c4bd2758c4a95e04756e5c67f2` | 已存在研究；不可作production base |
| `assets/candidates/warrior-identity-head-v01/warrior-head.blend` | `1874e6bdfc8ab0a229a4dd0b94d676d9c902fa4549e29e3cbc38a626d6796649` | 已存在研究；不可作production base |
| `assets/candidates/warrior-identity-head-v02/source-view-512.png` | `b0219dc87cf9db757d7089200868f4e79985482b3a0bf5740b2d2cb15c1f658f` | 已存在研究；不可作production base |
| `assets/candidates/warrior-identity-head-v02/warrior-head.blend` | `e8aefa7451be726e60d49d4a4d3ed5c4002fa15e1e7a5ad571591f343e73e5cc` | 已存在研究；不可作production base |
| `artifacts/ios/warrior-identity-head-v02/owner-review.json` | `7ac9406aace1bbdb11d8b3533828b719fa78ce074fceb0b33e8a1e20d4b7e6d4` | 已存在研究；不可作production base |
| `artifacts/ios/warrior-identity-head-v02/artifact-manifest-before-owner-review.json` | `377c74747e3e955e18b12ac8da023075a7ea65853a21a351e8b2856bfe571140` | 已存在研究；不可作production base |
| `artifacts/ios/warrior-identity-head-v02/REVIEW.md` | `95c7e9c0844e0937ddc85ad3feb49fba3bdf126d1607bc93d41143a50414ef8d` | 已存在研究；不可作production base |

Owner 2026-10-09否決身份/正式模型，接受研究。這輪只讀 `.blend` bytes 的SHA，未開啟或修改Blender工程；不能從副檔名/可編輯性推論角色身份正確。完整清單見 rejected-head-inventory.json。

Gate G-D00-0：512身份基準可追溯；1254 master未取得，來源完整性未全部PASS。
