import SwiftUI

struct TestListView: View {
    @Environment(TestStore.self) private var store
    @EnvironmentObject private var loginService: LoginService

    @State private var showCreateSheet = false
    
    var onProfileTapped: (() -> Void)?

    var body: some View {
        List {
            if !store.activeTests.isEmpty {
                Section("Active") {
                    ForEach(store.activeTests) { test in
                        NavigationLink(value: test.id) {
                            TestRowView(test: test)
                        }
                    }
                    .onDelete { offsets in
                        deleteTests(from: store.activeTests, at: offsets)
                    }
                }
            }

            if !store.futureTests.isEmpty {
                Section("Upcoming") {
                    ForEach(store.futureTests) { test in
                        NavigationLink(value: test.id) {
                            TestRowView(test: test)
                        }
                    }
                    .onDelete { offsets in
                        deleteTests(from: store.futureTests, at: offsets)
                    }
                }
            }

            if !store.pastTests.isEmpty {
                Section("Past") {
                    ForEach(store.pastTests) { test in
                        NavigationLink(value: test.id) {
                            TestRowView(test: test)
                        }
                    }
                    .onDelete { offsets in
                        deleteTests(from: store.pastTests, at: offsets)
                    }
                }
            }

            if store.tests.isEmpty && !store.isLoading {
                ContentUnavailableView(
                    "No Tests",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Create a new test to get started.")
                )
            }
        }
        .navigationTitle("Tests")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onProfileTapped?()
                } label: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .refreshable {
            await store.fetchTests()
        }
        .task(id: loginService.isLoggedIn) {
            if loginService.isLoggedIn {
                await store.fetchTests()
            }
        }
        .overlay {
            if store.isLoading && store.tests.isEmpty {
                ProgressView("Loading tests...")
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateTestView()
        }
        .alert("Error", isPresented: .init(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private func deleteTests(from section: [FrTest], at offsets: IndexSet) {
        for offset in offsets {
            let test = section[offset]
            Task {
                await store.deleteTest(id: test.id)
            }
        }
    }
}

// MARK: - Row

struct TestRowView: View {
    let test: FrTest

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(test.title)
                    .font(.headline)
                Spacer()
                StateBadge(state: test.state)
            }

            if let start = test.startTime {
                Text("Start: \(start.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let end = test.endTime {
                Text("End: \(end.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - State Badge

struct StateBadge: View {
    let state: FrTest.State

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch state {
        case .active: "Active"
        case .future: "Upcoming"
        case .past: "Ended"
        }
    }

    private var color: Color {
        switch state {
        case .active: .green
        case .future: .blue
        case .past: .secondary
        }
    }
}
