import SwiftUI

struct DataStatusBanner: View {
    let status: DataStatus

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
        }
        .padding(.vertical, 4)
    }

    private var title: String {
        switch status {
        case .empty:
            return "明細データはまだありません"
        case .loadedFromDocuments(let count, _):
            return "保存済みデータ: \(count)件"
        case .sample(let count):
            return "サンプルデータ表示中: \(count)件"
        case .imported(let count, _):
            return "取込済みデータ: \(count)件"
        case .error(let message):
            return message
        }
    }

    private var detail: String? {
        switch status {
        case .empty:
            return "JSONを読み込むか、サンプルデータを表示できます"
        case .loadedFromDocuments(_, let updatedAt):
            guard let updatedAt else {
                return nil
            }
            return "最終更新: \(Formatters.dateTime.string(from: updatedAt))"
        case .sample:
            return "このデータは実際の支出ではありません"
        case .imported(_, let importedAt):
            return "取込日時: \(Formatters.dateTime.string(from: importedAt))"
        case .error:
            return nil
        }
    }

    private var iconName: String {
        switch status {
        case .empty:
            return "tray"
        case .loadedFromDocuments:
            return "internaldrive"
        case .sample:
            return "testtube.2"
        case .imported:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }

    private var iconColor: Color {
        switch status {
        case .empty:
            return .secondary
        case .loadedFromDocuments:
            return .blue
        case .sample:
            return .orange
        case .imported:
            return .green
        case .error:
            return .red
        }
    }
}
