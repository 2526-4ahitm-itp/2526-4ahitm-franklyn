import SwiftUI

@main
struct MobileApp: App {
    @State private var store = TestStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        return LoginService.shared.resumeLogin(url: url)
    }
}
