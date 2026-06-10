import SwiftUI

struct POSView: View {
    @State private var scannedToken: String = ""
    @State private var priceText: String = ""
    @State private var showScanner = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = "結果"
    @State private var alertMessage = ""

    @State private var showSuccessOverlay = false
    @State private var successCashToPay: Int = 0
    @State private var successDiff: Int = 0
    @State private var successBalance: Int = 0

    private let storeId: String = "S001"

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("お会計")
                            .font(.largeTitle)
                            .bold()

                        Text("金額を入力してコードを読み取ってください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("金額")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("¥")
                                    .font(.title)
                                    .bold()

                                TextField("0", text: $priceText)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 34, weight: .bold))
                                    .textFieldStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(18)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("読み取り状態")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(scannedToken.isEmpty ? Color.gray.opacity(0.15) : Color.green.opacity(0.15))
                                        .frame(width: 42, height: 42)

                                    Image(systemName: scannedToken.isEmpty ? "qrcode.viewfinder" : "checkmark")
                                        .foregroundColor(scannedToken.isEmpty ? .gray : .green)
                                        .font(.headline)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(scannedToken.isEmpty ? "コード未読み取り" : "コード読み取り完了")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(scannedToken.isEmpty ? "スキャンすると決済できます" : "決済の準備ができました")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(18)
                        }

                        Button {
                            showScanner = true
                        } label: {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                Text("コードを読み取る")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }

                        Button {
                            executePayment()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("決済する")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(canPay ? Color.green : Color.gray.opacity(0.35))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .disabled(!canPay || isLoading)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .padding(.horizontal)

                    DisclosureGroup("テスト用入力") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("開発・確認用として手入力できます")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("qr_token", text: $scannedToken)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 24)
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            if showSuccessOverlay {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.green)
                    }

                    Text("決済が完了しました")
                        .font(.title3)
                        .bold()

                    Text("実際支払い ¥\(successCashToPay)")
                        .font(.headline)

                    Text("差額 \(successDiff >= 0 ? "+¥\(successDiff)" : "-¥\(abs(successDiff))")")
                        .foregroundColor(successDiff < 0 ? .red : .green)

                    Text("利用後残高 ¥\(successBalance)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .transition(.opacity)
            }
        }
        .navigationTitle("POS")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanner) {
            QRScannerView(scannedCode: $scannedToken)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    var canPay: Bool {
        !scannedToken.isEmpty && (Int(priceText) ?? 0) > 0
    }

    private func executePayment() {
        guard let price = Int(priceText), price > 0 else {
            alertTitle = "入力エラー"
            alertMessage = "正しい金額を入力してください。"
            showAlert = true
            return
        }

        guard !scannedToken.isEmpty else {
            alertTitle = "読み取りエラー"
            alertMessage = "コードを読み取ってください。"
            showAlert = true
            return
        }

        isLoading = true

        APIClient.pay(
            qrToken: scannedToken,
            price: price,
            storeId: storeId
        ) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let response):
                    successCashToPay = response.cash_to_pay
                    successDiff = response.diff
                    successBalance = response.balance_after

                    withAnimation {
                        showSuccessOverlay = true
                    }

                    priceText = ""
                    scannedToken = ""

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation {
                            showSuccessOverlay = false
                        }
                    }

                case .failure(let error):
                    alertTitle = "決済失敗"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}
