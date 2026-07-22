# QuickSplit

SPM ベースの macOS アプリ (Sparkle 自動更新付き)。

## ビルド / 検証 (完了条件)
```bash
swift build                # コンパイル検証 (最低条件)
./build.sh                 # 配布用 .app バンドル生成 (release、要署名 identity)
./build.sh debug           # debug ビルド
```
- テストターゲットなし。`swift build` が通ることが完了の最低条件
- UI 変更時は `dist/QuickSplit.app` を起動して目視確認

## 制約
- 署名 identity (`SIGN_IDENTITY`)・`appcast.xml` の配信設定を無断で変更しない
- `Generated/` は生成物。直接編集しない
