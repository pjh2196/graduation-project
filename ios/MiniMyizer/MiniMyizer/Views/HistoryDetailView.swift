import SwiftUI

struct HistoryDetailView: View {
    let record: PaymentRecord

    var formattedDate: String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"

        if let date = input.date(from: record.received_at) {
            let output = DateFormatter()
            output.locale = Locale(identifier: "ja_JP")
            output.dateFormat = "yyyy/MM/dd HH:mm"
            return output.string(from: date)
        }
        return record.received_at
    }

    var diffText: String {
        record.diff >= 0 ? "+¥\(record.diff)" : "-¥\(abs(record.diff))"
    }

    var diffColor: Color {
        record.diff < 0 ? .red : .green
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                VStack(spacing: 6) {
                    Text("取引詳細")
                        .font(.title2)
                        .bold()

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                VStack(spacing: 0) {
                    detailRow("店舗", record.store_id)
                    divider
                    detailRow("支払い金額", "¥\(record.price)")
                    divider
                    detailRow("実際支払い", "¥\(record.cash_to_pay)")
                    divider
                    detailDiffRow("差額", diffText)
                    divider
                    detailRow("利用前残高", "¥\(record.balance_before)")
                    divider
                    detailRow("利用後残高", "¥\(record.balance_after)")
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    var divider: some View {
        Divider().opacity(0.2)
    }

    func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .foregroundColor(.primary)
                .bold()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    func detailDiffRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .foregroundColor(diffColor)
                .bold()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
