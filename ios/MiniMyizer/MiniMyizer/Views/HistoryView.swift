import SwiftUI

struct HistoryView: View {
    let userId: String

    @State private var records: [PaymentRecord] = []
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(records) { record in
                    NavigationLink {
                        HistoryDetailView(record: record)
                    } label: {
                        HistoryRowCard(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("履歴")
        .onAppear {
            loadHistory()
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    func loadHistory() {
        APIClient.fetchHistory(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    records = data
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct HistoryRowCard: View {
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

    var iconColor: Color {
        record.diff < 0 ? .red : .green
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: record.diff < 0 ? "arrow.down.circle" : "arrow.up.circle")
                    .foregroundColor(iconColor)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("店舗 \(record.store_id)")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    Text("支払い ¥\(record.price)")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text("差額 \(diffText)")
                        .font(.subheadline)
                        .foregroundColor(iconColor)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("¥\(record.cash_to_pay)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(18)
    }
}
