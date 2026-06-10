import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "qrcode")
                Text("ホーム")
            }

            NavigationStack {
                HistoryView(userId: "test_user")
            }
            .tabItem {
                Image(systemName: "clock")
                Text("履歴")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("設定")
            }
        }
    }
}
