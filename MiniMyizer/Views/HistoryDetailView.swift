import SwiftUI
import CoreImage.CIFilterBuiltins

struct HistoryDetailView: View {
    let record: PaymentRecord
    let canShowReturnQR: Bool

    @Environment(\.dismiss) private var dismiss

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

    var isCancelled: Bool {
        record.is_cancelled ?? false
    }
    
    private let context = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()

    var returnQRImage: UIImage? {
        let data = String(record.id).data(using: .utf8)
        qrFilter.setValue(data, forKey: "inputMessage")

        guard let outputImage = qrFilter.outputImage else {
            return nil
        }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 12)

                VStack(spacing: 10) {
                    Text(isCancelled ? "取消済みの取引" : "お店に支払った金額")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("¥\(record.cash_to_pay)")
                        .font(.system(size: 56, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(isCancelled ? .secondary : .primary)

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if isCancelled {
                        Text("この取引は取消済みです")
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(26)

                VStack(spacing: 0) {
                    detailRow("商品金額", "¥\(record.price)")
                    divider
                    detailRow("端数残高", "¥\(record.balance_before) → ¥\(record.balance_after)")
                    divider
                    detailRow("店舗", record.store_id)
                    divider
                    detailRow("状態", isCancelled ? "取消済み" : "確定済み")
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(22)

                VStack(alignment: .leading, spacing: 10) {
                    Text("端数残高の変化")
                        .font(.headline)

                    Text("端数差額は, 端数残高の変化として表示しています。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(22)

                if !isCancelled && canShowReturnQR {
                    VStack(spacing: 14) {
                        Text("返品・取消用QR")
                            .font(.headline)

                        Text("返品・取消を行う場合は, 店舗スタッフにこのQRコードを提示してください。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if let image = returnQRImage {
                            Image(uiImage: image)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(18)
                        }

                        Text("取引ID：\(record.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(22)
                }
                
                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("支払い確認")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func convertCancelError(_ message: String) -> String {
        if message.contains("Only the latest payment can be cancelled") {
            return "最新の取引のみ取消できます。"
        } else if message.contains("already cancelled") {
            return "この取引はすでに取消済みです。"
        } else if message.contains("not found") {
            return "取消対象の取引が見つかりません。"
        } else {
            return message
        }
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
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}
