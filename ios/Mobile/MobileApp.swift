import SwiftUI

@main
struct MobileApp: App {
    @State private var store = TestStore()

    init() {
        // Load any previously stored auth state from keychain on app launch
        TokenStorage.shared.loadFromKeychain()
        print("[MobileApp] Loaded token storage, isAuthenticated: \(TokenStorage.shared.isAuthenticated)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .onOpenURL { url in
                    // Handle OAuth callback URL
                    _ = LoginService.shared.resumeLogin(url: url)
                }
        }
    }
}
