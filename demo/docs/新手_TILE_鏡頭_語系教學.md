# 新手教學：Tile 繪圖、Phantom Camera、Better Terrain、i18n

這份教學是給目前這個 Godot 專案用的。你可以照順序做，不需要一次全部懂。

## 目前我已經幫你放好的東西

- Phantom Camera：`res://addons/phantom_camera`
- Better Terrain：`res://addons/better-terrain`
- Godot i18n 翻譯檔：`res://demo/i18n/en.po`、`res://demo/i18n/zh.po`
- 主要海洋岩石 Tile 圖：`res://demo/assets/tiles/ocean_rock_modular_tiles.png`
- 主要海洋岩石 TileSet：`res://demo/assets/tiles/ocean_rock_modular_tileset.tres`
- 舊版簡單草稿 Tile 圖：`res://demo/assets/tiles/demo_floor_tilesheet.png`
- 舊版簡單草稿 TileSet：`res://demo/assets/tiles/demo_floor_tileset.tres`
- 給你畫地圖用的空白空間：`res://demo/scenes/tools/tile_paint_workspace.tscn`

## 1. 怎麼打開繪圖空間

1. 打開 Godot。
2. 開專案 `D:/小畢製/20260516/godot-small-main`。
3. 在左下 FileSystem 找到：
   `demo/tile_paint_workspace.tscn`
4. 雙擊打開。
5. 這個場景已經放入玩家、ESC 暫停選單、GameUI 和測試用邊界。
6. 場景裡主要只需要點 `PaintHere_TileMapLayer` 畫地圖。
7. 不用另外放 StaticBody。你在 `PaintHere_TileMapLayer` 畫上去的石頭 tile 已經有碰撞。

## 2. 怎麼用 TileMapLayer 畫地板

1. 點選左邊 Scene 裡的 `PaintHere_TileMapLayer`。
2. 下方會出現 TileMap 編輯面板。
3. 選一個 tile。
4. 在畫面上用滑鼠左鍵刷地板。
5. 想擦掉就選橡皮擦工具，或按住對應的刪除工具。

如果你看不到 TileMap 面板，確認你選到的是 `TileMapLayer`，不是整個 `TilePaintWorkspace`。

## 3. 怎麼測試你畫的地圖

1. 打開 `tile_paint_workspace.tscn`。
2. 先在 `PaintHere_TileMapLayer` 畫地板。
3. 按右上角 Play Current Scene，或按 `F6`。
4. 玩家會出生在場景左側。
5. 你可以用平常的移動、跳、衝刺、攻擊測手感。
6. 按 `Esc` 會打開你原本的暫停選單。

如果玩家掉下去，代表該位置沒有畫可站立的 tile。這個場景現在不放額外測試地板，因為你的目標是「畫什麼就測什麼」。

## 4. 新海洋岩石 tilesheet

主要素材是：

`res://demo/assets/tiles/ocean_rock_modular_tiles.png`

它是從你給的 `bosslevel_title3.png` 放進專案的版本。格線設定：

- 欄數：8
- 列數：7
- 每格大小：181 x 155
- 透明背景
- 已做成 TileSet collision，可以讓玩家踩、撞牆、測平台

也就是說：你在 `PaintHere_TileMapLayer` 上畫一格石頭，那一格石頭就是地板或牆。玩家會直接跟它碰撞。

最適合用法：

- 大塊岩石：做主牆、主地板、Boss 房外框。
- 長條平台：做可跳躍平台。
- 斜坡：可先當視覺裝飾，真的要做斜坡手感再另外調 collision。
- 倒三角岩塊：適合當天花板垂下來的海底岩石。
- 最下面一排方塊：適合填充大面積牆體或背景。

## 5. 舊 32x32 tilesheet 每格是什麼

這張圖是 8 欄 x 4 列，每格 32x32。

第一列：
- 普通實心地板
- 上緣亮邊
- 下緣暗邊
- 左牆邊
- 右牆邊
- 左上角
- 右上角
- 裂痕地板

第二列：
- 平台中段
- 平台左端
- 平台右端
- 細橋
- 潮濕牆
- 裂痕潮濕牆
- 暗部填充
- 小石頭裝飾

第三列：
- 水中地板
- 水面邊
- 水中牆
- 珊瑚陰影
- 海草陰影
- 柱子
- 柱子上緣
- 破柱子

第四列：
- Boss 房地板
- Boss 房上緣
- Boss 房裂痕
- Boss 房石板
- 發光礦點
- 暗邊
- 空格
- 空格

## 4. Aseprite Tilemap 怎麼配合

Aseprite 不是 Godot 外掛，它是美術軟體。

最簡單流程：

1. 用 Aseprite 打開：
   `demo/assets/tiles/demo_floor_tilesheet.png`
2. 設定 Grid：
   - Width：32
   - Height：32
3. 開啟 Tilemap layer。
4. 用 tile 模式改每一格。
5. 存回同一張 PNG。
6. 回 Godot 後，如果畫面沒更新：
   - 對 PNG 右鍵
   - Reimport

注意：不要改圖片尺寸，不要把 32x32 格線弄歪。Godot 的 TileSet 是按照這個格線切的。

## 5. Better Terrain 怎麼用

Better Terrain 是讓 TileMap 自動接邊更好用的外掛。

啟用後你會在 TileSet/TileMap 編輯介面看到 Better Terrain 相關工具。概念是：

1. 先選 TileSet。
2. 把哪些 tile 屬於同一種地形標起來，例如「地板」「牆」「水中牆」。
3. 回 TileMapLayer 用 Better Terrain 的刷子畫。
4. 它會自動幫你選比較適合的邊角 tile。

新手建議先不用急著設定很完整。先用普通 TileMapLayer 刷出大概地圖，再慢慢把常用的地板邊角整理成 Terrain。

## 6. Phantom Camera 怎麼用

Phantom Camera 是 Godot 4 的進階運鏡系統，類似 Unity Cinemachine。

最簡單用法：

1. 場景裡保留你的 Camera2D。
2. 新增一個 `PhantomCameraHost`，讓它控制 Camera2D。
3. 新增一個 `PhantomCamera2D`。
4. 把 `PhantomCamera2D` 的 Follow Target 設成玩家。
5. 之後你可以再新增另一個 `PhantomCamera2D` 給 Boss、遠景、死亡演出。
6. 透過 Priority 或切換 active camera，讓鏡頭從玩家切到 Boss 或遠景。

目前 boss 二階段我先用既有 Player camera profile 做拉遠，因為那段已經能跑。Phantom Camera 已經裝好，下一步可以把 boss 二階段運鏡正式改成 Phantom Camera 節點切換。

## 7. i18n 怎麼用

Godot 內建翻譯系統，不是外掛。

目前翻譯檔在：

- `i18n/zh.po`
- `i18n/en.po`

新增文字的方式：

1. 在 `zh.po` 加：
   ```
   msgid "PROMPT_NEW_TEXT"
   msgstr "你的中文"
   ```
2. 在 `en.po` 加：
   ```
   msgid "PROMPT_NEW_TEXT"
   msgstr "Your English text"
   ```
3. 在程式裡用：
   ```
   tr("PROMPT_NEW_TEXT")
   ```

注意：`msgid` 建議用英文代號，不要直接用中文句子。這樣之後整理比較乾淨。

## 8. 我的建議工作順序

1. 先在 `tile_paint_workspace.tscn` 用普通 TileMap 畫地圖草稿。
2. 地圖好玩後，再回 Aseprite 修 tilesheet 美術。
3. 常用地板確定後，再設定 Better Terrain 自動接邊。
4. Boss 演出需要變漂亮時，再把目前 boss 二階段 camera profile 改成 Phantom Camera 切鏡。
5. 所有提示字最後再統一丟進 `i18n/*.po`。
