# MailBudget データ種別分離・読み込み設計 仕様書

## 1. 目的

本仕様書は、MailBudget アプリにおいて、サンプルデータと実データが混同される問題を防止するための設計を定義する。

現状の問題は、アプリ起動時に実データが存在しない場合、バンドル済みの `sample_transactions.json` が自動的に読み込まれ、ユーザーから見ると実データのように表示されてしまう点にある。

その結果、以下のような誤解が発生する。

- 実際にメールを読み込めているのか分からない
- なぜ 5 件だけ表示されるのか分からない
- サンプルデータなのか実データなのか判断できない
- JSON を更新したのに、古い端末内データが表示され続ける可能性がある

本仕様では、以下を実現する。

1. サンプルデータと実データを明確に分離する
2. 初回起動時にサンプルデータを自動投入しない
3. 現在表示中のデータ種別を画面上に表示する
4. データ読み込み結果を件数付きで表示する
5. 最終読み込み元と最終更新日時を確認できるようにする
6. 実データが存在しない場合は空状態を表示する

---

## 2. 対象範囲

### 2.1 対象

本仕様の対象は以下である。

- iOS アプリ側のデータ読み込み設計
- サンプルデータの扱い
- JSON 取込結果の扱い
- メール抽出結果の扱い
- 画面上のデータ状態表示
- 最終同期状態の管理
- データ保存・読み込み責務の分離

### 2.2 対象外

以下は本仕様では直接扱わない。

- IMAP によるメール取得処理そのもの
- Python 抽出器のパーサ精度改善
- カード会社別の本文解析ルール
- App Store 公開用の審査対応
- iCloud 同期
- バックエンド連携

---

## 3. 設計方針

### 3.1 基本方針

MailBudget では、表示されている明細が何に由来するかを常に明示する。

具体的には、明細データを以下の種別に分類する。

| データ種別 | 説明 |
|---|---|
| `sample` | 開発・デモ用のサンプルデータ |
| `mailExtracted` | メール抽出器によって生成された実データ |
| `importedJSON` | ユーザーが JSON ファイルから取り込んだデータ |
| `manual` | ユーザーが手入力したデータ |

サンプルデータは、開発・テスト・デモ用途に限定する。通常の起動時に自動で保存・表示してはならない。

### 3.2 初回起動時の方針

初回起動時に端末内の実データが存在しない場合、アプリは空状態を表示する。

```text
明細データはまだありません。
メール抽出結果の JSON を読み込むか、サンプルデータを表示してください。
```

初回起動時に `sample_transactions.json` を自動的に読み込んではならない。

### 3.3 サンプルデータの方針

サンプルデータは、ユーザーが明示的に「サンプルデータを表示」を選択した場合のみ読み込む。

サンプルデータを読み込んだ場合、画面上に必ず以下を表示する。

```text
現在表示中: サンプルデータ
件数: 5件
```

サンプルデータを実データとして保存してはならない。保存する場合でも、必ず `sourceKind = sample` を付与する。

---

## 4. 機能要件

### 4.1 データ種別管理

| ID | 要件 |
|---|---|
| FR-DATA-001 | アプリは各明細データにデータ種別を保持できる |
| FR-DATA-002 | アプリはサンプルデータ、メール抽出データ、JSON取込データ、手入力データを区別できる |
| FR-DATA-003 | アプリは現在表示中のデータ種別を画面上に表示できる |
| FR-DATA-004 | アプリはデータ種別ごとの件数を表示できる |
| FR-DATA-005 | アプリはデータ種別で明細をフィルタできる |

### 4.2 初回起動

| ID | 要件 |
|---|---|
| FR-BOOT-001 | 初回起動時に端末内データが存在しない場合、アプリは空状態を表示する |
| FR-BOOT-002 | 初回起動時にサンプルデータを自動投入しない |
| FR-BOOT-003 | 空状態画面では、JSON取込、メール抽出結果取込、サンプル表示の導線を表示する |
| FR-BOOT-004 | 保存済み実データが存在する場合、アプリは保存済みデータを読み込む |
| FR-BOOT-005 | 保存済みデータの読み込みに失敗した場合、エラーを表示し、サンプルデータへ自動フォールバックしない |

### 4.3 サンプルデータ

| ID | 要件 |
|---|---|
| FR-SAMPLE-001 | サンプルデータはユーザーの明示操作がある場合のみ表示できる |
| FR-SAMPLE-002 | サンプルデータ表示中は、画面上に「サンプルデータ表示中」と明示する |
| FR-SAMPLE-003 | サンプルデータは通常の同期結果として扱わない |
| FR-SAMPLE-004 | サンプルデータの読み込みボタンは、通常の同期ボタンと分離する |
| FR-SAMPLE-005 | サンプルデータは実データの保存ファイルに混在させない |
| FR-SAMPLE-006 | サンプルデータを保存する場合は、すべての明細に `sourceKind = sample` を付与する |

### 4.4 JSON取込

| ID | 要件 |
|---|---|
| FR-IMPORT-001 | アプリは JSON ファイルから明細データを取り込める |
| FR-IMPORT-002 | JSON 取込後、読み込み件数を表示する |
| FR-IMPORT-003 | JSON 取込後、新規登録件数を表示する |
| FR-IMPORT-004 | JSON 取込後、重複件数を表示する |
| FR-IMPORT-005 | JSON 取込後、失敗件数を表示する |
| FR-IMPORT-006 | JSON から取り込んだ明細には `sourceKind = importedJSON` または `mailExtracted` を付与する |
| FR-IMPORT-007 | JSON の `sourceMessageId` が既存データと一致する場合、重複として扱う |
| FR-IMPORT-008 | JSON の形式が不正な場合、既存データを破壊せずエラーを表示する |

### 4.5 同期状態表示

| ID | 要件 |
|---|---|
| FR-SYNC-001 | アプリは最終読み込み日時を表示できる |
| FR-SYNC-002 | アプリは最終読み込み元を表示できる |
| FR-SYNC-003 | アプリは最終読み込み件数を表示できる |
| FR-SYNC-004 | アプリは最終読み込み結果の詳細を表示できる |
| FR-SYNC-005 | アプリは同期結果として、取得件数・登録件数・重複件数・失敗件数を保持できる |

---

## 5. 非機能要件

| ID | 要件 |
|---|---|
| NFR-DATA-001 | サンプルデータは実データと混在しないように管理する |
| NFR-DATA-002 | データ読み込みに失敗しても、既存データを破壊しない |
| NFR-DATA-003 | データ保存前に JSON デコード結果を検証する |
| NFR-DATA-004 | サンプルデータは開発・テスト・デモ用途に限定する |
| NFR-DATA-005 | 実データが存在しない場合、空状態を明示する |
| NFR-DATA-006 | ユーザーが現在見ているデータの由来を誤認しない UI とする |
| NFR-DATA-007 | 読み込み処理と表示処理の責務を分離する |
| NFR-DATA-008 | 端末内保存データとバンドル済みサンプルデータの読み込み経路を分離する |

---

## 6. データモデル

### 6.1 TransactionSourceKind

明細データの由来を表す。

```swift
enum TransactionSourceKind: String, Codable, CaseIterable, Identifiable {
    case sample
    case mailExtracted
    case importedJSON
    case manual

    var id: String { rawValue }
}
```

### 6.2 Transaction

既存の `Transaction` に以下の項目を追加する。

```swift
struct Transaction: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var amount: Int
    var merchant: String
    var category: String
    var paymentMethod: String
    var source: String
    var sourceMessageId: String
    var isConfirmed: Bool
    var createdAt: Date
    var updatedAt: Date
    var mailReceivedAt: Date?
    var snippet: String?

    // 追加項目
    var sourceKind: TransactionSourceKind
    var importedAt: Date?
    var importBatchId: UUID?
}
```

### 6.3 DataStatus

現在のデータ状態を表す。

```swift
enum DataStatus: Equatable {
    case empty
    case loadedFromDocuments(count: Int, updatedAt: Date?)
    case sample(count: Int)
    case imported(count: Int, importedAt: Date)
    case error(message: String)
}
```

### 6.4 ImportBatch

1 回のデータ取込結果を表す。

```swift
struct ImportBatch: Identifiable, Codable {
    let id: UUID
    var source: ImportSource
    var startedAt: Date
    var finishedAt: Date
    var inputFileName: String?
    var totalCount: Int
    var insertedCount: Int
    var updatedCount: Int
    var duplicateCount: Int
    var failedCount: Int
    var message: String
}
```

### 6.5 ImportSource

取込元を表す。

```swift
enum ImportSource: String, Codable, CaseIterable {
    case bundledSample
    case documentsJSON
    case fileImporter
    case mailExtractor
    case manual
}
```

---

## 7. 責務分離設計

### 7.1 現状の問題

現状では、`TransactionStore` が以下の責務を同時に持っている。

- 明細データの保持
- Documents 内データの読み込み
- バンドル済みサンプルデータの読み込み
- データ保存
- エクスポート
- 同期メッセージ管理

この構造では、保存済みデータが存在しない場合にサンプルデータを自動読み込みする処理が入り込みやすい。

### 7.2 改善後の構成

責務を以下のように分離する。

```text
TransactionStore
  ├─ 明細データの状態管理
  ├─ 明細の追加・更新・削除
  └─ UI向けの集計値提供

TransactionRepository
  ├─ Documents 内の実データ読み込み
  ├─ Documents への実データ保存
  └─ 保存済みデータの存在確認

SampleDataProvider
  ├─ バンドル済みサンプルデータ読み込み
  └─ Preview / Demo 用データ提供

TransactionImportService
  ├─ JSON ファイルの検証
  ├─ JSON 取込
  ├─ 重複判定
  └─ ImportBatch 生成

SyncStateStore
  ├─ 最終同期日時の保存
  ├─ 最終同期元の保存
  └─ 最終同期結果の保存
```

### 7.3 ファイル構成案

```text
MailBudget/
  ├─ Models/
  │   ├─ Transaction.swift
  │   ├─ TransactionSourceKind.swift
  │   ├─ ImportBatch.swift
  │   ├─ ImportSource.swift
  │   └─ DataStatus.swift
  │
  ├─ Services/
  │   ├─ TransactionStore.swift
  │   ├─ TransactionRepository.swift
  │   ├─ SampleDataProvider.swift
  │   ├─ TransactionImportService.swift
  │   └─ SyncStateStore.swift
  │
  ├─ Views/
  │   ├─ HomeView.swift
  │   ├─ EmptyStateView.swift
  │   ├─ DataStatusBanner.swift
  │   ├─ ImportResultView.swift
  │   ├─ TransactionListView.swift
  │   ├─ SummaryView.swift
  │   └─ SettingsView.swift
  │
  └─ Resources/
      └─ sample_transactions.json
```

---

## 8. 起動時処理仕様

### 8.1 起動時フロー

```text
アプリ起動
↓
Documents/transactions.json の存在確認
↓
存在する場合
  ↓
  デコードを試行
  ↓
  成功: 実データとして読み込み
  失敗: エラー表示
↓
存在しない場合
  ↓
  空状態を表示
```

### 8.2 禁止事項

起動時に以下を行ってはならない。

- `sample_transactions.json` を自動で読み込む
- サンプルデータを実データ保存先へ自動保存する
- データ読み込み失敗時にサンプルデータへ自動フォールバックする
- ユーザーに通知せずデータを上書きする

### 8.3 疑似コード

```swift
func loadOnLaunch() {
    do {
        if repository.exists() {
            let rows = try repository.loadTransactions()
            transactions = rows
            dataStatus = .loadedFromDocuments(
                count: rows.count,
                updatedAt: repository.lastModifiedAt()
            )
            lastSyncMessage = "保存済みデータを \(rows.count) 件読み込みました"
        } else {
            transactions = []
            dataStatus = .empty
            lastSyncMessage = "明細データはまだありません"
        }
    } catch {
        transactions = []
        dataStatus = .error(message: "保存済みデータを読み込めませんでした")
        lastSyncMessage = "保存済みデータを読み込めませんでした"
    }
}
```

---

## 9. サンプルデータ表示仕様

### 9.1 表示フロー

```text
ユーザーが「サンプルデータを表示」を押す
↓
SampleDataProvider が sample_transactions.json を読み込む
↓
各 Transaction に sourceKind = sample を付与
↓
TransactionStore に一時表示データとして反映
↓
DataStatus を sample にする
↓
画面上に「サンプルデータ表示中」と表示
```

### 9.2 仕様

サンプルデータは、原則として実データ保存先に保存しない。

ただし、デモ用途で保存する実装を許可する場合は、以下を満たすこと。

- `sourceKind = sample` を必ず付与する
- 実データ取込結果と混ぜない
- サンプルデータ削除ボタンを提供する
- サンプル表示中であることを常に表示する

### 9.3 疑似コード

```swift
func showSampleData() {
    do {
        let rows = try sampleDataProvider.loadSampleTransactions()
        transactions = rows.map { transaction in
            var copied = transaction
            copied.sourceKind = .sample
            copied.importedAt = Date()
            copied.importBatchId = nil
            return copied
        }
        dataStatus = .sample(count: transactions.count)
        lastSyncMessage = "サンプルデータを \(transactions.count) 件表示中です"
    } catch {
        dataStatus = .error(message: "サンプルデータを読み込めませんでした")
        lastSyncMessage = "サンプルデータを読み込めませんでした"
    }
}
```

---

## 10. JSON取込仕様

### 10.1 取込フロー

```text
ユーザーが JSON ファイルを選択
↓
ファイルを読み込み
↓
JSON デコード
↓
形式検証
↓
sourceMessageId による重複判定
↓
新規データを追加
↓
必要に応じて既存データを更新
↓
ImportBatch を生成
↓
取込結果を表示
```

### 10.2 取込結果表示

JSON 取込後、以下を表示する。

```text
JSON取込結果

読み込み元: transactions.json
読み込み件数: 128件
新規登録: 123件
更新: 0件
重複: 5件
失敗: 0件
取込日時: 2026/06/30 21:15
```

### 10.3 重複判定

優先する重複判定キーは以下とする。

1. `sourceMessageId`
2. `paymentMethod + date + amount + merchant`
3. `mailReceivedAt + amount + merchant`

`sourceMessageId` が一致する場合は、原則として同一メール由来の明細とみなし、重複として扱う。

### 10.4 失敗時の扱い

JSON 取込に失敗した場合、既存データを変更してはならない。

```text
JSONを読み込めませんでした。
ファイル形式を確認してください。
既存の明細データは変更されていません。
```

---

## 11. 画面仕様

### 11.1 ホーム画面

ホーム画面には、現在のデータ状態を表示する。

#### 表示項目

- 現在表示中のデータ種別
- 明細件数
- 今月の支出合計
- 最終読み込み日時
- 最終読み込み元
- 最終読み込み結果
- JSON取込ボタン
- メール抽出結果取込ボタン
- サンプルデータ表示ボタン

#### 表示例: 実データ

```text
現在表示中: メール抽出データ
明細件数: 128件
最終更新: 2026/06/30 21:15
最終取込: transactions.json
```

#### 表示例: サンプルデータ

```text
現在表示中: サンプルデータ
明細件数: 5件
このデータは実際の支出ではありません。
```

#### 表示例: 空状態

```text
明細データはまだありません。
メール抽出結果の JSON を読み込むか、サンプルデータを表示してください。
```

### 11.2 明細一覧画面

明細一覧画面には、フィルタとしてデータ種別を追加する。

#### フィルタ項目

- すべて
- メール抽出データ
- JSON取込データ
- 手入力データ
- サンプルデータ

### 11.3 設定画面

設定画面には以下を追加する。

- 最終取込履歴
- 保存済み実データ削除
- サンプルデータ表示
- サンプルデータ削除
- 開発用データリセット

サンプル関連操作は、通常の同期操作とは分離して表示する。

---

## 12. UI コンポーネント仕様

### 12.1 DataStatusBanner

現在のデータ状態を画面上部に表示するコンポーネント。

```swift
struct DataStatusBanner: View {
    let status: DataStatus

    var body: some View {
        switch status {
        case .empty:
            Text("明細データはまだありません")
        case .loadedFromDocuments(let count, let updatedAt):
            Text("保存済みデータ: \(count)件")
        case .sample(let count):
            Text("サンプルデータ表示中: \(count)件")
        case .imported(let count, let importedAt):
            Text("取込済みデータ: \(count)件")
        case .error(let message):
            Text(message)
        }
    }
}
```

### 12.2 EmptyStateView

データが存在しない場合に表示する。

```swift
struct EmptyStateView: View {
    var onImportJSON: () -> Void
    var onShowSample: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("明細データはまだありません")
                .font(.headline)

            Text("メール抽出結果の JSON を読み込むと、支出明細を表示できます。")
                .foregroundStyle(.secondary)

            Button("JSONを読み込む", action: onImportJSON)
            Button("サンプルデータを見る", action: onShowSample)
        }
    }
}
```

### 12.3 ImportResultView

JSON 取込後の結果を表示する。

```swift
struct ImportResultView: View {
    let batch: ImportBatch

    var body: some View {
        List {
            LabeledContent("読み込み件数", value: "\(batch.totalCount)件")
            LabeledContent("新規登録", value: "\(batch.insertedCount)件")
            LabeledContent("更新", value: "\(batch.updatedCount)件")
            LabeledContent("重複", value: "\(batch.duplicateCount)件")
            LabeledContent("失敗", value: "\(batch.failedCount)件")
            LabeledContent("取込元", value: batch.inputFileName ?? "不明")
        }
    }
}
```

---

## 13. 実装タスク

### 13.1 モデル追加

| タスクID | 内容 |
|---|---|
| TASK-DATA-001 | `TransactionSourceKind.swift` を追加する |
| TASK-DATA-002 | `DataStatus.swift` を追加する |
| TASK-DATA-003 | `ImportBatch.swift` を追加する |
| TASK-DATA-004 | `ImportSource.swift` を追加する |
| TASK-DATA-005 | `Transaction` に `sourceKind`, `importedAt`, `importBatchId` を追加する |

### 13.2 サービス分離

| タスクID | 内容 |
|---|---|
| TASK-SERVICE-001 | `TransactionRepository` を追加する |
| TASK-SERVICE-002 | `SampleDataProvider` を追加する |
| TASK-SERVICE-003 | `TransactionImportService` を追加する |
| TASK-SERVICE-004 | `SyncStateStore` を追加する |
| TASK-SERVICE-005 | `TransactionStore` からサンプル自動読み込み処理を削除する |

### 13.3 起動時処理変更

| タスクID | 内容 |
|---|---|
| TASK-BOOT-001 | `load()` から `importBundledSample()` 呼び出しを削除する |
| TASK-BOOT-002 | 保存済みデータがなければ `transactions = []` とする |
| TASK-BOOT-003 | 保存済みデータがなければ `dataStatus = .empty` とする |
| TASK-BOOT-004 | データ読み込み失敗時にサンプルへフォールバックしない |

### 13.4 UI 変更

| タスクID | 内容 |
|---|---|
| TASK-UI-001 | `DataStatusBanner` を追加する |
| TASK-UI-002 | `EmptyStateView` を追加する |
| TASK-UI-003 | `ImportResultView` を追加する |
| TASK-UI-004 | ホーム画面に現在のデータ種別を表示する |
| TASK-UI-005 | 明細一覧にデータ種別フィルタを追加する |
| TASK-UI-006 | サンプル表示ボタンを通常同期ボタンから分離する |

### 13.5 JSON取込

| タスクID | 内容 |
|---|---|
| TASK-IMPORT-001 | ファイル選択による JSON 取込を実装する |
| TASK-IMPORT-002 | JSON デコード前にファイル形式を検証する |
| TASK-IMPORT-003 | `sourceMessageId` による重複判定を実装する |
| TASK-IMPORT-004 | 取込結果を `ImportBatch` として保存する |
| TASK-IMPORT-005 | 取込後に `ImportResultView` を表示する |

---

## 14. 移行仕様

### 14.1 既存データへの対応

既存の `transactions.json` には `sourceKind` が存在しない可能性がある。

その場合、読み込み時に以下のように補完する。

| 条件 | 補完する sourceKind |
|---|---|
| `sourceMessageId` が `sample-` で始まる | `sample` |
| `source` が `iCloud Mail` | `mailExtracted` |
| それ以外 | `importedJSON` |

### 14.2 後方互換デコード

`Transaction` の `init(from decoder:)` で `sourceKind` が存在しない場合のデフォルト値を設定する。

```swift
sourceKind = try container.decodeIfPresent(TransactionSourceKind.self, forKey: .sourceKind)
    ?? inferSourceKind(source: source, sourceMessageId: sourceMessageId)
```

### 14.3 サンプルデータの扱い

既存保存データに `sample-001` から `sample-005` のみが含まれる場合、アプリは以下の警告を表示する。

```text
現在保存されているデータはサンプルデータの可能性があります。
実データとして使う場合は、メール抽出結果 JSON を読み込んでください。
```

---

## 15. テスト仕様

### 15.1 単体テスト

| テストID | 内容 | 期待結果 |
|---|---|---|
| TEST-001 | 保存済みデータがない状態で起動する | 空状態になる |
| TEST-002 | 保存済みデータがない状態で起動する | サンプルデータは自動読み込みされない |
| TEST-003 | サンプル表示ボタンを押す | サンプルデータが表示される |
| TEST-004 | サンプル表示時 | `dataStatus = .sample` になる |
| TEST-005 | 実データ JSON を取り込む | `sourceKind = mailExtracted` または `importedJSON` になる |
| TEST-006 | 同じ `sourceMessageId` の JSON を再取込する | 重複として扱われる |
| TEST-007 | 不正 JSON を取り込む | 既存データが保持される |
| TEST-008 | `sourceKind` なしの旧データを読み込む | 自動補完される |

### 15.2 UI テスト

| テストID | 内容 | 期待結果 |
|---|---|---|
| UI-001 | 空状態画面を表示する | 「明細データはまだありません」と表示される |
| UI-002 | サンプルデータを表示する | 「サンプルデータ表示中」と表示される |
| UI-003 | JSON 取込後 | 取込件数・重複件数・失敗件数が表示される |
| UI-004 | 明細一覧でデータ種別フィルタを使う | 指定種別の明細だけ表示される |
| UI-005 | 保存済みデータを読み込む | データ種別と件数が表示される |

---

## 16. 受け入れ条件

本仕様の対応完了条件は以下である。

1. アプリ初回起動時にサンプル 5 件が自動表示されない
2. 実データがない場合は空状態が表示される
3. サンプルデータを表示するには明示操作が必要である
4. サンプルデータ表示中であることが画面上に明示される
5. JSON 取込後に、読み込み件数・新規登録件数・重複件数・失敗件数が表示される
6. 現在表示中のデータ種別が画面上に表示される
7. 明細ごとに `sourceKind` が保持される
8. 起動時に保存済みデータが壊れていても、サンプルデータへ自動フォールバックしない
9. 既存のサンプル 5 件のみが保存されている場合、サンプルデータの可能性を警告できる
10. 明細一覧でデータ種別による絞り込みができる

---

## 17. 仕様変更後のユーザー体験

### 17.1 初回起動時

```text
明細データはまだありません。

メール抽出結果の JSON を読み込むと、
支出明細を表示できます。

[JSONを読み込む]
[サンプルデータを見る]
```

### 17.2 サンプル表示時

```text
現在表示中: サンプルデータ
明細件数: 5件
このデータは実際の支出ではありません。

[実データJSONを読み込む]
[サンプル表示を終了]
```

### 17.3 実データ取込後

```text
現在表示中: メール抽出データ
明細件数: 128件
最終取込: 2026/06/30 21:15

取込結果:
読み込み 128件 / 新規 123件 / 重複 5件 / 失敗 0件
```

---

## 18. 実装上の注意

### 18.1 `sample_transactions.json` の位置づけ

`sample_transactions.json` は引き続き Resources に配置してよい。

ただし、役割は以下に限定する。

- SwiftUI Preview
- UI デモ
- 動作確認
- テスト用 fixture

通常起動時の初期データとして使ってはならない。

### 18.2 既存の `importBundledSample()`

既存の `importBundledSample()` は、以下のいずれかに変更する。

1. `showSampleData()` に改名し、保存しない一時表示にする
2. `importSampleForDemo()` に改名し、デモ専用であることを明示する
3. Debug ビルド限定にする

推奨は `showSampleData()` への改名である。

### 18.3 `load()` の変更

`load()` は、以下の責務だけを持つ。

- Documents 内の保存済み実データを読む
- 存在しなければ空状態にする
- 失敗すればエラー状態にする

`load()` からサンプルデータを読む処理を削除する。

---

## 19. まとめ

本仕様では、MailBudget におけるデータ読み込み設計を以下の方針へ変更する。

```text
変更前:
  実データがなければサンプルデータを自動読み込み

変更後:
  実データがなければ空状態を表示
  サンプルデータは明示操作時のみ表示
  現在のデータ種別・件数・最終取込結果を常に表示
```

この変更により、「なぜ 5 件だけ表示されているのか分からない」という状態を防ぎ、ユーザーが現在見ているデータの由来を正確に判断できるようにする。
