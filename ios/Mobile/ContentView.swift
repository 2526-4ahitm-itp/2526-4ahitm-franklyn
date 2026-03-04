import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TestListView()
                .navigationDestination(for: String.self) { testId in
                    TestDetailView(testId: testId)
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(TestStore())
}
