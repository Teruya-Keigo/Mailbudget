import SwiftUI

@main
struct MailBudgetApp: App {
    @StateObject private var store = TransactionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

