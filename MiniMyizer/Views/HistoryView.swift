import SwiftUI

struct HistoryView: View {
    let userId: String

    @State private var records: [PaymentRecord] = []
    @State private var errorMessage: String?
    @State private var showError = false
    
    var latestCancelablePaymentId: Int? {
        records.first(where: { !($0.is_cancelled ?? false) })?.id
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(records) { record in
                    NavigationLink {
                        HistoryDetailView(
                            record: record,
                            canShowReturnQR: record.id == latestCancelablePaymentId
                        )
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
        if isCancelled {
            return "取消済み"
        }
        return record.diff >= 0 ? "+¥\(record.diff)" : "-¥\(abs(record.diff))"
    }
    
    var isCancelled: Bool {
        record.is_cancelled ?? false
    }
    
    var diffColor: Color {
        if isCancelled {
            return .secondary
        }
        return record.diff >= 0 ? .green : .red
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("店舗 \(record.store_id)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(diffText)
                    .font(.title2.bold())
                    .monospacedDigit()
                    .foregroundColor(diffColor)
                
                Text(isCancelled ? "取引取消" : "端数残高")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(18)
        }
    }
}
