# Godot 畢業製作

Godot 4.6 project for the current playable demo.

## Project Layout

- `demo/scenes/levels`: playable spaces, including normal room, water room, and boss room.
- `demo/scenes`: reusable scenes such as player, enemies, UI, map pieces, and interactables.
- `demo/scripts`: game code and shared systems.
- `demo/assets`: art, audio, fonts, generated assets, tiles, and imported reference assets.
- `demo/shaders`: project shaders.
- `demo/i18n`: localization files.
- `addons`: installed Godot editor/runtime plugins.

## Version

Current version: `0.1.0`

## Description# Godot 畢業製作

這是使用 **Godot 4.6** 製作的畢業製作專案。  
目前版本為可遊玩的 2D橫向卷軸Demo，主要展示遊戲的核心操作、場景探索、Boss 戰流程與基本系統。

## 專案狀態

目前專案仍在開發中，並非完整遊戲版本。  
此版本主要用於測試與展示以下內容：

- 玩家移動、跳躍、攻擊與游泳
- 一般關卡與水中場景
- Boss 戰第一階段與第二階段
- 場景切換與存檔點
- UI、血量顯示與基本互動
- 渲染效果與 Shader 測試
- 可自訂操作按鍵

## Project Layout

- `demo/scenes/levels`：可遊玩場景，包含一般房間、水中房間與 Boss 房間。
- `demo/scenes`：可重複使用的場景，例如玩家、敵人、UI、地圖物件與互動物件。
- `demo/scripts`：遊戲程式碼與共用系統。
- `demo/assets`：美術、音效、字體、生成素材、地圖素材與參考素材。
- `demo/shaders`：專案使用的 Shader。
- `demo/i18n`：多語系與在地化文字檔。
- `addons`：Godot 編輯器或遊戲執行時使用的外掛套件。

## 操作方式

本遊戲支援自訂按鍵，以下為目前預設操作：

| 按鍵 | 功能 |
|---|---|
| A / D | 左右移動 |
| Z | 跳躍 |
| X | 攻擊 |
| E | 互動 |
| ESC | 暫停 / 離開選單 |

## 目前開發重點

後續會優先調整以下內容：

- 統一場景美術風格，減少畫面割裂感
- 調整角色、敵人、Boss 與背景的視覺比例
- 強化 Boss 戰節奏與攻擊回饋
- 改善受擊特效、震動、音效與發光效果
- 調整平台與關卡配置，讓移動與戰鬥更順暢
- 優化 UI、血量顯示與提示文字

## Version

Current version: `0.1.0`

## Development Environment

- Godot 4.6
- Git
- GitHub

## Collaboration

開始修改前，請先拉取 GitHub 最新版本：

```bash
git pull origin main

畢業製作 Godot 專案。
