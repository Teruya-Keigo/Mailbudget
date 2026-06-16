import SwiftUI

struct TransactionDetailView: View {
    @EnvironmentObject private var store: TransactionStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Transaction

    init(transaction: Transaction) {
        _draft = State(initialValue: transaction)
    }

    var body: some View {
        Form {
            Section("明細") {
                DatePicker("利用日", selection: $draft.date, displayedComponents: .date)
                TextField("利用先", text: $draft.merchant)
                TextField("金額", value: $draft.amount, format: .number)
                    .keyboardType(.numberPad)
                Picker("カテゴリ", selection: $draft.category) {
                    ForEach(Transaction.categories, id: \.self) { Text($0) }
                }
                TextField("支払い方法", text: $draft.paymentMethod)
                Toggle("確認済み", isOn: $draft.isConfirmed)
            }

            Section("取得元") {
                LabeledContent("ソース", value: draft.source)
                LabeledContent("メールID", value: draft.sourceMessageId)
                if let snippet = draft.snippet, !snippet.isEmpty {
                    Text(snippet)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    store.upsert(draft)
                    dismiss()
                } label: {
                    Label("保存", systemImage: "checkmark")
                }

                Button(role: .destructive) {
                    store.delete(draft)
                    dismiss()
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
        .navigationTitle("明細詳細")
    }
}

