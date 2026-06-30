import SwiftUI

struct EmptyStateView: View {
    var onImportJSON: () -> Void
    var onShowSample: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("明細データはまだありません")
                    .font(.headline)
                Text("メール抽出結果の JSON を読み込むと、支出明細を表示できます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: onImportJSON) {
                Label("JSONを読み込む", systemImage: "doc.badge.plus")
            }

            Button(action: onShowSample) {
                Label("サンプルデータを見る", systemImage: "testtube.2")
            }
        }
        .padding(.vertical, 8)
    }
}
