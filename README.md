# Mail Budget App

メール連携型の個人用家計簿アプリ MVP です。

このリポジトリは仕様書の推奨順に合わせて、次の2つで構成しています。

- `extractor/`: iCloud Mail からカード利用通知メールを取得し、JSON/CSV に出力する Python 抽出器
- `ios/MailBudget/`: 抽出済み JSON を読み込み、明細一覧・月別/カテゴリ別集計・編集・削除・エクスポートを行う SwiftUI アプリ

## Python 抽出器

設定ファイルを作成します。

```sh
cp extractor/config.example.json extractor/config.json
```

`extractor/config.json` に iCloud メールアドレスと App 用パスワードを設定してください。現在はエポスカード、三菱 UFJ-VISA デビット、JCB カード／ショッピング利用通知に対応しています。

```sh
python3 extractor/main.py --config extractor/config.json --output ios/MailBudget/MailBudget/Resources/sample_transactions.json
```

対象期間を指定したい場合は、月単位または日付範囲を指定できます。

```sh
python3 extractor/main.py --config extractor/config.json --month 2026-05 --output ios/MailBudget/MailBudget/Resources/sample_transactions.json
```

```sh
python3 extractor/main.py --config extractor/config.json --start-date 2026-05-01 --end-date 2026-05-31 --output ios/MailBudget/MailBudget/Resources/sample_transactions.json
```

App 用パスワードは Apple ID の管理画面で発行したものを使います。通常の Apple ID パスワードは使わないでください。

特定のパーサを無効化したい場合は、`disabledParserTypes` に `epos_card`、`mufg_visa_debit`、`jcb_shopping` のいずれかを追加してください。

同じ利用先・同じ金額の通知メールが複数届いた場合も、メール1通につき1明細として取り込みます。同じメールを再実行で二重取り込みしないため、IMAP UID を含む `sourceMessageId` で管理しています。

取り込み状況を確認したい場合は、既存JSONを作り直しつつ詳細ログを出せます。

```sh
python3 extractor/main.py --config extractor/config.json --month 2026-05 --replace --verbose --output ios/MailBudget/MailBudget/Resources/sample_transactions.json
```

件名の表記ゆれで取り逃がしていそうな場合は、件名の事前フィルタを外して確認できます。

```sh
python3 extractor/main.py --config extractor/config.json --month 2026-05 --replace --verbose --no-subject-prefilter --output ios/MailBudget/MailBudget/Resources/sample_transactions.json
```

## iOS アプリ

Xcode で `ios/MailBudget/MailBudget.xcodeproj` を開き、`MailBudget` ターゲットを実行してください。

初回起動時はバンドル済みの `sample_transactions.json` を読み込みます。以後の編集内容は端末内の Documents に保存されます。取得した期間の履歴は、アプリ下部の `明細` タブで全件確認できます。

## テスト

```sh
python3 -m unittest discover extractor/tests
```
