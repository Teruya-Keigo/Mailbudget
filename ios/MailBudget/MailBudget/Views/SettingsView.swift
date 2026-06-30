import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TransactionStore
    @State private var appPassword = ""
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section("読み込み状態") {
                    DataStatusBanner(status: store.dataStatus)
                    Text(store.lastSyncMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let batch = store.lastImportBatch {
                        ImportResultView(batch: batch)
                    }
                }

                Section("メール接続設定") {
                    TextField("メールアドレス", text: $store.mailSource.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("App用パスワード", text: $appPassword)
                    TextField("IMAPサーバー", text: $store.mailSource.imapHost)
                        .textInputAutocapitalization(.never)
                    TextField("ポート番号", value: $store.mailSource.imapPort, format: .number)
                        .keyboardType(.numberPad)
                    Toggle("SSLを使用", isOn: $store.mailSource.useSSL)
                    Stepper("同期対象: \(store.mailSource.syncDays)日", value: $store.mailSource.syncDays, in: 1...365)
                    Button {
                        KeychainStore.savePassword(appPassword, account: store.mailSource.emailAddress)
                        store.lastSyncMessage = "接続情報を保存しました"
                    } label: {
                        Label("接続情報を保存", systemImage: "key")
                    }
                }

                Section("エクスポート") {
                    Button {
                        exportURL = store.exportJSON()
                    } label: {
                        Label("JSONを出力", systemImage: "doc")
                    }
                    Button {
                        exportURL = store.exportCSV()
                    } label: {
                        Label("CSVを出力", systemImage: "tablecells")
                    }
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("共有", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                Section("データ") {
                    Button {
                        store.showSampleData()
                    } label: {
                        Label("サンプルデータを表示", systemImage: "testtube.2")
                    }

                    if store.isShowingSample {
                        Button {
                            store.clearSampleData()
                        } label: {
                            Label("サンプル表示を終了", systemImage: "xmark.circle")
                        }
                    }

                    Button(role: .destructive) {
                        store.deleteAll()
                    } label: {
                        Label("保存済み実データ削除", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                appPassword = KeychainStore.loadPassword(account: store.mailSource.emailAddress)
            }
        }
    }
}
