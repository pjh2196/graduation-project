import SwiftUI
import Combine
import CoreImage.CIFilterBuiltins

struct HomeView: View {
    @State private var qrToken: String = ""
    @State private var expiresAt: Date?
    @State private var remainingTime: Int = 0
    @State private var isLoading = false
    @State private var currentBalance: Int = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let qrContext = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()

    private let userId = "test_user"

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("かんたん決済")
                            .font(.headline)

                        Text("お店でこのコードを提示してください")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("利用可能額")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("¥\(currentBalance)")
                            .font(.title3)
                            .bold()
                    }
                }

                if let barcodeImage = generateBarcode(from: qrToken) {
                    Image(uiImage: barcodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 72)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(14)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .frame(height: 72)
                        .overlay {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("バーコード")
                                    .foregroundColor(.black.opacity(0.6))
                            }
                        }
                }

                if let qrImage = generateQRCode(from: qrToken) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(20)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 220, height: 220)
                        .overlay {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("コードを準備中")
                                    .foregroundColor(.gray)
                            }
                        }
                }

                HStack(spacing: 8) {
                    Text("有効期限: \(formattedRemainingTime)")
                        .font(.subheadline)
                        .foregroundColor(remainingTime <= 10 ? .red : .gray)

                    Button {
                        issueToken()
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(28)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("ホーム")
        .padding(.bottom, 24)
        .onAppear {
            if qrToken.isEmpty {
                issueToken()
            }
            loadCurrentBalance()
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
    }
}

extension HomeView {
    var formattedRemainingTime: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func issueToken() {
        isLoading = true

        APIClient.issueToken(userId: userId) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let data):
                    qrToken = data.qr_token
                    expiresAt = Date().addingTimeInterval(30)
                    remainingTime = 30
                    loadCurrentBalance()

                case .failure(let error):
                    print("issueToken error:", error.localizedDescription)
                }
            }
        }
    }

    func updateTimer() {
        guard let expiresAt = expiresAt else { return }

        let diff = Int(ceil(expiresAt.timeIntervalSinceNow))
        remainingTime = max(diff, 0)

        if remainingTime == 0 && !isLoading {
            issueToken()
        }
    }

    func loadCurrentBalance() {
        APIClient.fetchHistory(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let latest = data.first {
                        currentBalance = latest.balance_after
                    } else {
                        currentBalance = 0
                    }

                case .failure:
                    currentBalance = 0
                }
            }
        }
    }

    func generateQRCode(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }

        let data = Data(string.utf8)
        qrFilter.setValue(data, forKey: "inputMessage")

        guard let outputImage = qrFilter.outputImage else { return nil }

        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        guard let cgImage = qrContext.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    func generateBarcode(from string: String) -> UIImage? {
        guard !string.isEmpty else { return nil }

        let data = Data(string.utf8)
        barcodeFilter.setValue(data, forKey: "inputMessage")

        guard let outputImage = barcodeFilter.outputImage else { return nil }

        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 6))

        guard let cgImage = qrContext.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
