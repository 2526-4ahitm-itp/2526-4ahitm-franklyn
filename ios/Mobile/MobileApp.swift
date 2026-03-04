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
}
