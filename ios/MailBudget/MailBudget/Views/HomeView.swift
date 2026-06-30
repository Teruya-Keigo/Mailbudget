import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var store: TransactionStore
    @State private var isImportingJSON = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DataStatusBanner(status: store.dataStatus)
                    if store.hasSavedSampleOnlyWarning {
                        Label("保存済みデータはサンプルデータの可能性があります", systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                if store.transactions.isEmpty {
                    Section {
                        EmptyStateView(
                            onImportJSON: { isImportingJSON = true },
                            onShowSample: { store.showSampleData() }
                        )
                    }
                } else {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今月の支出")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(Formatters.yen(store.totalThisMonth))
                                .font(.system(size: 34, weight: .bold))
                        }
                        .padding(.vertical, 8)
                    }

                    Section("データ種別") {
                        ForEach(store.sourceKindCounts, id: \.kind) { item in
                            HStack {
                                Text(item.kind.displayName)
                                Spacer()
                                Text("\(item.count)件")
                                    .fontWeight(.semibold)
                            }
                        }
                    }

                    Section("カテゴリ別") {
                        ForEach(store.categoryTotals(for: Date()), id: \.category) { item in
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text(Formatters.yen(item.total))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }

                Section("読み込み") {
                    Button {
                        isImportingJSON = true
                    } label: {
                        Label("JSONを読み込む", systemImage: "doc.badge.plus")
                    }

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

                    Text(store.lastSyncMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let batch = store.lastImportBatch {
                    Section("取込結果") {
                        ImportResultView(batch: batch)
                    }
                }
            }
            .navigationTitle("Mail Budget")
            .navigationDestination(for: Transaction.self) { transaction in
                TransactionDetailView(transaction: transaction)
            }
            .fileImporter(isPresented: $isImportingJSON, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    store.importJSON(from: url)
                case .failure:
                    store.lastSyncMessage = "JSONファイルを選択できませんでした"
                }
            }
        }
    }
}
