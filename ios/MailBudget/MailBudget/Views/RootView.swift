import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }

            TransactionListView()
                .tabItem { Label("明細", systemImage: "list.bullet.rectangle") }

            SummaryView()
                .tabItem { Label("集計", systemImage: "chart.bar") }

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
    }
}

