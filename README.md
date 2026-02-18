# MinimalTimecard

Mac向けの超シンプルなメニューバー常駐型タイムカードアプリ。

出勤・退勤・休憩の打刻のみに特化し、極限まで摩擦を減らした設計です。完全オフライン・ローカル完結で動作します。

## Features

- **メニューバー常駐** - Dockに表示されず、メニューバーからワンクリックで操作
- **3つのアクションのみ** - 出勤 / 休憩 / 退勤。余計な機能なし
- **リアルタイムタイマー** - 実働時間をカウントアップ表示（休憩時間は自動除外）
- **状態復元** - アプリを再起動しても勤務状態とタイマーを正確に復元
- **月次レポート出力** - ワンクリックで今月の勤務表をCSVで出力
- **完全ローカル** - サーバー通信なし。データはCSVファイルとして `~/Documents/Timecard/` に保存

## Install

### Homebrew

```bash
brew install ogawa-where/tap/minimal-timecard
```

### GitHub Releases

[Releases](https://github.com/ogawa-where/minimal-timecard-mac/releases) から `MinimalTimecard.zip` をダウンロードし、解凍した `MinimalTimecard.app` を `/Applications` に移動してください。

> **Note:** 署名なしアプリのため、初回起動時に「開発元を確認できません」と表示されます。
> `MinimalTimecard.app` を右クリック →「開く」を選択すると起動できます。

### Build from Source

```bash
git clone https://github.com/ogawa-where/minimal-timecard-mac.git
cd minimal-timecard-mac
swift build -c release
./scripts/package-app.sh release
open build/MinimalTimecard.app
```

## Usage

### 基本操作

1. メニューバーの時計アイコンをクリック
2. `出勤` を押すとタイマー開始
3. `休憩` → `再開` で休憩を挟める（何度でも可）
4. `退勤` を押すと記録完了

### 月次レポート

`今月の勤務表を出力` をクリックすると、`~/Documents/Timecard/YYYY-MM_report.csv` が生成されます。

出力後、ログファイルの削除を選択できます。ログを残せば何度でも再出力可能です。

### データ形式

打刻ログ (`log.csv`):

```
Date,Time,Action
2026/02/18,10:00:00,出勤
2026/02/18,12:00:00,休憩
2026/02/18,13:00:00,再開
2026/02/18,19:00:00,退勤
```

月次レポート (`YYYY-MM_report.csv`):

```
日付,出勤,退勤,休憩時間,実働時間
2026/02/18,10:00,19:00,01:00:00,08:00:00
```

## Requirements

- macOS 15.0 (Sequoia) or later

## License

MIT
