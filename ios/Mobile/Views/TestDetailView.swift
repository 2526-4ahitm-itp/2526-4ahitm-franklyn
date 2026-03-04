import SwiftUI

struct TestDetailView: View {
    @Environment(TestStore.self) private var store

    let testId: String

    private var test: FrTest? {
        store.tests.first { $0.id == testId }
    }

    var body: some View {
        Group {
            if let test {
                List {
                    Section("Details") {
                        DetailRow(label: "Title", value: test.title)
                        DetailRow(label: "Status", value: stateLabel(test.state))
                        DetailRow(
                            label: "Start Time",
                            value: test.startTime?.formatted(date: .long, time: .shortened) ?? "Not set"
                        )
                        DetailRow(
                            label: "End Time",
                            value: test.endTime?.formatted(date: .long, time: .shortened) ?? "Not set"
                        )
                        if let prefix = test.testAccountPrefix {
                            DetailRow(label: "Account Prefix", value: prefix)
                        }
                        if let teacherId = test.teacherId {
                            DetailRow(label: "Teacher ID", value: teacherId)
                        }
                    }

                    Section {
                        switch test.state {
                        case .future:
                            Button("Start Test") {
                                Task { await store.startTest(id: test.id) }
                            }
                            .tint(.green)

                        case .active:
                            Button("End Test") {
                                Task { await store.endTest(id: test.id) }
                            }
                            .tint(.orange)

                        case .past:
                            Text("This test has ended.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Button("Delete Test", role: .destructive) {
                            Task { await store.deleteTest(id: test.id) }
                        }
                    }
                }
                .navigationTitle(test.title)
            } else {
                ContentUnavailableView(
                    "Test Not Found",
                    systemImage: "questionmark.folder"
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stateLabel(_ state: FrTest.State) -> String {
        switch state {
        case .active: "Active"
        case .future: "Upcoming"
        case .past: "Ended"
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
