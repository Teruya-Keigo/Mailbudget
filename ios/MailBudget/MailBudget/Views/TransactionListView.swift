import SwiftUI

enum TransactionSort: String, CaseIterable, Identifiable {
    case dateDescending = "日付順"
    case amountDescending = "金額順"

    var id: String { rawValue }
}

struct TransactionListView: View {
    @EnvironmentObject private var store: TransactionStore
    @State private var selectedCategory = "すべて"
    @State private var sort = TransactionSort.dateDescending

    private var categories: [String] {
        ["すべて"] + Transaction.categories
    }

    private var rows: [Transaction] {
        let filtered = selectedCategory == "すべて"
            ? store.transactions
            : store.transactions.filter { $0.category == selectedCategory }
        switch sort {
        case .dateDescending:
            return filtered.sorted { $0.date > $1.date }
        case .amountDescending:
            return filtered.sorted { $0.amount > $1.amount }
        }
    }

    private var totalAmount: Int {
        rows.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("\(rows.count)件", systemImage: "number")
                        Spacer()
                        Text(Formatters.yen(totalAmount))
                            .fontWeight(.semibold)
                    }
                }

                Section {
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    Picker("並び順", selection: $sort) {
                        ForEach(TransactionSort.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section {
                    ForEach(rows) { transaction in
                        NavigationLink(value: transaction) {
                            TransactionRow(transaction: transaction)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.delete(rows[index])
                        }
                    }
                }
            }
            .navigationTitle("明細")
            .navigationDestination(for: Transaction.self) { transaction in
                TransactionDetailView(transaction: transaction)
            }
        }
    }
}
