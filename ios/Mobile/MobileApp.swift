import SwiftUI
import AppAuth

@main
struct MobileApp: App {
    @State private var store = ExamStore()
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environmentObject(LoginService.shared)
                .preferredColorScheme(darkModeEnabled ? .dark : nil)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return LoginService.shared.resumeLogin(url: url)
    }
}
