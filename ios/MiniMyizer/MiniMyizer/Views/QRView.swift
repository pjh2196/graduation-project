import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRView: View {
    @State private var qrToken: String = ""
    @State private var expiresAt: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String = ""
    @State private var showError = false
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    let userId: String = "test_user"
    
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage()
    }
    
    func fetchQRCode() {
        isLoading = true
        
        APIClient.issueToken(userId: userId) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    qrToken = response.qr_token
                    expiresAt = response.expires_at
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("QRコード")
                    .font(.largeTitle)
                
                if !qrToken.isEmpty {
                    Image(uiImage: generateQRCode(from: qrToken))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    Text("qr_token: \(qrToken)")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("expiresAt: \(expiresAt)")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("QRコードがありません")
                        .foregroundColor(.gray)
                }
                
                Button("再生成") {
                    fetchQRCode()
                }
                .padding()
                .disabled(isLoading)
                
                NavigationLink("POSへ") {
                    POSView()
                }
                .padding(.top, 8)
                
                NavigationLink("履歴を見る") {
                    HistoryView(userId: userId)
                }
                .padding(.top, 8)
            }
            
            if isLoading {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView("読み込み中...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
        .navigationTitle("QRコード")
        .onAppear {
            if qrToken.isEmpty {
                fetchQRCode()
            }
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}
