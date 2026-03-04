import Apollo
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("hello world")
            .task {
                do {
                    print("Fetching")
                    let response = try await apolloClient.fetch(query: FranklynAPI.GetTestsQuery())
                    print(response.data?.tests?.count) // Luke Skywalker
                } catch {
                    print("Error fetching hero: \(error)")
                }
            }
    }
}

#Preview {
    ContentView()
}
