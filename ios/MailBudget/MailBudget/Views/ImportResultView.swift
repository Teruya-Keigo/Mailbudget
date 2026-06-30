import SwiftUI

struct ImportResultView: View {
    let batch: ImportBatch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("読み込み元", value: batch.inputFileName ?? "不明")
            LabeledContent("読み込み件数", value: "\(batch.totalCount)件")
            LabeledContent("新規登録", value: "\(batch.insertedCount)件")
            LabeledContent("更新", value: "\(batch.updatedCount)件")
            LabeledContent("重複", value: "\(batch.duplicateCount)件")
            LabeledContent("失敗", value: "\(batch.failedCount)件")
            LabeledContent("取込日時", value: Formatters.dateTime.string(from: batch.finishedAt))
        }
    }
}
