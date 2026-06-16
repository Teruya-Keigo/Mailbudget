import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var store: TransactionStore

    var body: some View {
        NavigationStack {
            List {
                Section("月別支出") {
                    ForEach(store.monthlyTotals(), id: \.month) { item in
                        HStack {
                            Text(item.month)
                            Spacer()
                            Text(Formatters.yen(item.total))
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section("今月のカテゴリ別支出") {
                    ForEach(store.categoryTotals(for: Date()), id: \.category) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text(Formatters.yen(item.total))
                            }
                            ProgressView(value: Double(item.total), total: Double(max(store.totalThisMonth, 1)))
                        }
                    }
                }

                Section("今月の支払い方法別支出") {
                    ForEach(store.paymentMethodTotals(for: Date()), id: \.paymentMethod) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.paymentMethod)
                                Spacer()
                                Text(Formatters.yen(item.total))
                            }
                            ProgressView(value: Double(item.total), total: Double(max(store.totalThisMonth, 1)))
                        }
                    }
                }
            }
            .navigationTitle("集計")
        }
    }
}
