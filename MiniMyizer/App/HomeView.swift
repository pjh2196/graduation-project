import SwiftUI
import Combine
import CoreImage.CIFilterBuiltins

struct HomeView: View {
    @State private var qrToken: String = ""
    @State private var expiresAt: Date?
    @State private var remainingTime: Int = 0
    @State private var isLoading = false
    @State private var currentBalance: Int = 0
    @State private var balanceRefreshTick: Int = 0

    @State private var pendingPayment: PendingPaymentResult?
    @State private var showPendingPayment = false
    @State private var lastPendingId: String = ""
    @State private var showCompletedPayment = false
    @State private var completedBalance: Int = 0
    @State private var completedPendingId: String = ""

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let qrContext = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()
    private let barcodeFilter = CIFilter.code128BarcodeGenerator()

    private let userId = "test_user"
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            VStack(spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("かんたん決済")
                            .font(.title3.bold())

                        Text("お店にこのQRコードを提示してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    VStack(spacing: 6) {
                        Text("端数残高")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("¥\(currentBalance)")
                            .font(.system(size: 40, weight: .bold))
                            .monospacedDigit()
                            .foregroundColor(.white)
                    }
                    .frame(width: 128)
                    .padding(.vertical, 18)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
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
            checkPendingPayment()
        }
        .onReceive(timer) { _ in
            updateTimer()
            checkPendingPayment()

            balanceRefreshTick += 1
            if balanceRefreshTick % 3 == 0 {
                loadCurrentBalance()
            }
        }
        .sheet(isPresented: $showPendingPayment) {
            if let pending = pendingPayment {
                PendingPaymentConfirmView(pending: pending) {
                    showPendingPayment = false
                    pendingPayment = nil
                    loadCurrentBalance()
                }
            }
        }
        .sheet(isPresented: $showCompletedPayment) {
            PaymentCompletedView(balanceAfter: completedBalance) {
                showCompletedPayment = false
                loadCurrentBalance()
            }
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
                    expiresAt = Date().addingTimeInterval(300)
                    remainingTime = 300
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
                        if latest.is_cancelled ?? false {
                            currentBalance = latest.balance_before
                        } else {
                            currentBalance = latest.balance_after
                        }
                    } else {
                        currentBalance = 0
                    }

                case .failure:
                    currentBalance = 0
                }
            }
        }
    }

    func checkPendingPayment() {
        APIClient.fetchLatestPaymentStatus(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    guard let status = status else {
                        return
                    }

                    if status.status == "pending" {
                        if status.pending_id != lastPendingId {
                            pendingPayment = status
                            lastPendingId = status.pending_id
                            showPendingPayment = true
                        }
                    } else if status.status == "confirmed" {
                        if status.pending_id != completedPendingId {
                            showPendingPayment = false
                            pendingPayment = nil
                            completedPendingId = status.pending_id
                            completedBalance = status.balance_after
                            showCompletedPayment = true
                            loadCurrentBalance()
                        }
                    } else if status.status == "cancelled" {
                        if status.pending_id == lastPendingId {
                            pendingPayment = nil
                            showPendingPayment = false
                            lastPendingId = ""
                        }
                    }

                case .failure(let error):
                    print("fetchLatestPaymentStatus error:", error.localizedDescription)
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

struct PendingPaymentConfirmView: View {
    let pending: PendingPaymentResult
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Spacer(minLength: 12)

                    VStack(spacing: 10) {
                        Text("お店に支払う金額")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("¥\(pending.cash_to_pay)")
                            .font(.system(size: 56, weight: .bold))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        Text("この金額をお店にお支払いください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(26)
                    .padding(.horizontal)

                    VStack(spacing: 0) {
                        resultRow(title: "商品金額", value: "¥\(pending.price)")
                        divider
                        resultRow(title: "端数残高", value: "¥\(pending.balance_before) → ¥\(pending.balance_after)")
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(22)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("店舗側で現金確認後に取引が確定します")
                            .font(.headline)

                        Text("この画面では支払う現金額を確認できます。取引確定後, 履歴に反映されます。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(22)
                    .padding(.horizontal)

                    Button {
                        onClose()
                    } label: {
                        Text("確認")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 24)
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("支払い確認")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var divider: some View {
        Divider().opacity(0.2)
    }

    func resultRow(title: String, value: String) -> some View {
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

struct PaymentCompletedView: View {
    let balanceAfter: Int
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.18))
                        .frame(width: 96, height: 96)

                    Image(systemName: "checkmark")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.green)
                }

                Text("取引が完了しました")
                    .font(.title2.bold())

                VStack(spacing: 10) {
                    Text("現在の端数残高")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("¥\(balanceAfter)")
                        .font(.system(size: 56, weight: .bold))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(26)
                .padding(.horizontal)

                Button {
                    onClose()
                } label: {
                    Text("確認")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical, 24)
        }
    }
}
