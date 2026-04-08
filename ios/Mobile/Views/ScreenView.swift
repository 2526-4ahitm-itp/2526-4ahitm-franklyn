import SwiftUI

struct ScreenView: View {
    @State private var store = WebsocketStore()
    @State private var testStore = TestStore()
    @State private var selectedTest: FrTest?
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            testSelector
            sentinelGrid
        }
        .task {
            await testStore.fetchTests()
        }
        .onAppear {
            store.connectWebsocket()
        }
        .onDisappear {
            store.disconnect()
        }
    }
    
    private var testSelector: some View {
        VStack(alignment: .leading) {
            Text("Select Test")
                .font(.headline)
            
            if testStore.activeTests.isEmpty {
                Text("No active tests")
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(testStore.activeTests) { test in
                            TestChip(
                                test: test,
                                isSelected: selectedTest?.id == test.id,
                                onTap: {
                                    selectTest(test)
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(8)
        .frame(height: 80)
        .background(Color.secondary.opacity(0.1))
    }
    
    private func selectTest(_ test: FrTest) {
        if selectedTest?.id == test.id {
            selectedTest = nil
            store.clearPinFilter()
        } else {
            selectedTest = test
            if let pin = test.pin {
                store.setPinFilter(pin: pin)
            }
        }
    }
    
    private var sentinelGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(store.framesBySentinel.keys.sorted(), id: \.self) { sentinelId in
                    VStack {
                        if let image = store.framesBySentinel[sentinelId] {
                            Image(uiImage: image)
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
    }
}

struct TestChip: View {
    let test: FrTest
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(test.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let pin = test.pin {
                    Text("PIN: \(pin)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.white)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}