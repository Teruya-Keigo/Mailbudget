import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: TransactionStore

    var body: some View {
        NavigationStack {
            List {
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

                Section {
                    Button {
                        store.importBundledSample()
                    } label: {
                        Label("サンプルJSONを再読み込み", systemImage: "arrow.clockwise")
                    }
                    Text(store.lastSyncMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Mail Budget")
            .navigationDestination(for: Transaction.self) { transaction in
                TransactionDetailView(transaction: transaction)
            }
        }
    }
}
