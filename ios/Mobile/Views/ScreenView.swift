import SwiftUI

struct ScreenView: View {
    @State private var store = WebsocketStore()
    
    // Define how many columns you want for your sentinels
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                // Iterate through all sentinels we have received frames for
                ForEach(store.framesBySentinel.keys.sorted(), id: \.self) { sentinelId in
                    VStack {
                        if let uiImage = store.framesBySentinel[sentinelId] {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        Text(sentinelId)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .onAppear {
            store.connectWebsocket()
        }
        .onDisappear {
            store.disconnect()
        }
    }
}
