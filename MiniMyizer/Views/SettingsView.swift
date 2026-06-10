import SwiftUI

struct SettingsView: View {
    @AppStorage("api_base_url") private var apiBaseURL: String = "http://127.0.0.1:8001"

    var body: some View {
        Form {
            Section("接続設定") {
                TextField("API Base URL", text: $apiBaseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }

            Section("テスト") {
                NavigationLink {
                    POSView()
                } label: {
                    Label("POSテスト画面", systemImage: "terminal")
                }
            }

            Section("情報") {
                Text("かんたん決済アプリ")
                    .foregroundColor(.primary)

                Text("QRコード / バーコード / 履歴確認")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("設定")
    }
}
