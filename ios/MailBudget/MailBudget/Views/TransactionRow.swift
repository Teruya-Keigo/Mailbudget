import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.merchant)
                        .font(.headline)
                        .lineLimit(1)
                    if !transaction.isConfirmed {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .accessibilityLabel("未確認")
                    }
                }
                Text("\(Formatters.date.string(from: transaction.date)) ・ \(transaction.category)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Formatters.yen(transaction.amount))
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 4)
    }
}

