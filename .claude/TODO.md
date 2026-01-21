# TODO

## 本番リリーススクリプト作成

TestFlight用スクリプト (`upload-testflight.sh`) とは別に、App Store本番用のスクリプトを作成する。

**違い:**
- TestFlight: `--dart-define=ENABLE_TEST_MODE=true` を付与（テストモード有効）
- 本番: フラグなし（テストモード無効）

**作成予定ファイル:**
- `.claude/scripts/upload-appstore.sh`

**実装時の参考:**
```bash
# 本番用はフラグなしでビルド
flutter build ipa --release
```
