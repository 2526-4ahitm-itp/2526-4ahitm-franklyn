import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TestListView()
                .navigationDestination(for: String.self) { testId in
                    TestDetailView(testId: testId)
                }
            Button("Login") {
                LoginService.shared.discoverConfiguration(test: "")
            }
            NavigationLink(destination: ScreenView()) {
                Text("Screens")
            }
        }
    }
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        return LoginService.shared.resumeLogin(url: url)
    }
}

#Preview {
    ContentView()
        .environment(TestStore())
}
