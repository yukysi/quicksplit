# QuickSplit

macOS 用の画面分割ショートカットマネージャ。menu bar に常駐し、ウィンドウを左右半分・4分割・3分割・中央・最大化などに一発で整列するグローバルホットキーを、GUI で自由に編集できます。

Rectangle / Magnet 相当の機能を、SwiftUI ネイティブで軽量に実装したものです。

## 機能

- **14種の分割アクション**: 左右半分 / 上下半分 / 4分割 / 横3分割 / 中央寄せ / 最大化 / ほぼ最大化 / 元に戻す
- **menu bar 一覧ポップオーバー**: 各アクションのショートカットをその場で編集・即実行
- **ユーザー編集可能なホットキー**: 任意のキーコンビネーションを割り当て、永続化
- **ログイン時起動**: 設定からトグル
- **マルチディスプレイ対応**: ウィンドウが載っているスクリーン基準で計算

## インストール

### 要件
- macOS 14 (Sonoma) 以上
- Apple Silicon / Intel Mac（リリースビルドは現在のホスト CPU 向け）

### ビルド
```bash
git clone https://github.com/YukiYasui/quicksplit.git
cd quicksplit
./build.sh release
open dist/QuickSplit.app
```

`dist/QuickSplit.app` を `~/Applications` 等へコピーすれば常用できます。

## Accessibility 権限の付与

ウィンドウを操作するため、macOS の Accessibility API への許可が必要です。

1. QuickSplit を起動するとポップオーバーに警告バナーが出ます
2. 「システム設定を開く」ボタンで System Settings → **プライバシーとセキュリティ** → **アクセシビリティ** が開きます
3. QuickSplit のトグルを ON にします
4. バナーが消えれば完了（数秒で自動反映）

## 使い方

1. menu bar の `▣` アイコンをクリック
2. ポップオーバー内の各行の録音フィールドをクリックしてホットキーを割り当て
3. 割り当てたキーを押すとフォーカス中のウィンドウが分割される
4. 行右端の ▶︎ ボタンでその場で実行もできる
5. 「元に戻す」は直前のフレームへ復元（履歴 20 回まで）

## アーキテクチャ

- **Swift Package** (`Package.swift`) — 単一 executable target
- **`Sources/QuickSplit/Core/`**
  - `WindowAction.swift` — 全分割アクションの enum と表示メタデータ
  - `WindowLayoutCalculator.swift` — スクリーン矩形 → 目標フレーム計算（純粋関数）
  - `WindowManager.swift` — AXUIElement で最前面ウィンドウをリサイズ、履歴管理
  - `AccessibilityGuard.swift` — AX 権限チェック + 設定誘導
  - `ShortcutRegistry.swift` — [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) への登録
- **`Sources/QuickSplit/Views/`** — SwiftUI（MenuBarExtra `.window` style / Settings）
- **`Resources/Info.plist`** — `LSUIElement=true` で Dock に出さない
- **`build.sh`** — `swift build` → .app バンドル組み立て → ad-hoc 署名

## 依存

- [sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (MIT)

## ライセンス

MIT
