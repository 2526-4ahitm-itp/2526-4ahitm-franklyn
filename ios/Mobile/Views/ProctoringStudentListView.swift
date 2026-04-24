import SwiftUI

struct ProctoringStudentListView: View {
    let students: [ProctoringStudentRecord]
    let examPin: Int?

    @Binding var selectedNameKeys: Set<String>
    @State private var store = WebsocketStore.shared

    var body: some View {
        List(sortedStudents) { student in
            Button {
                toggleFavourite(for: student)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(student.name)
                            .font(.body)

                        statusBadge(for: student)

                        Spacer()

                        Image(systemName: selectedNameKeys.contains(student.nameKey) ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                    }

                    Text(lastActiveText(for: student))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Students")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.enterProctoringScope(pin: examPin)
        }
        .onDisappear {
            store.exitProctoringScope()
        }
        .overlay {
            if sortedStudents.isEmpty {
                ContentUnavailableView(
                    "No Students Yet",
                    systemImage: "person.2.slash",
                    description: Text("Students will appear here after they connect to this exam.")
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text("Favourites")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(selectedNameKeys.count)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private var sortedStudents: [ProctoringStudentRecord] {
        students.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    @ViewBuilder
    private func statusBadge(for student: ProctoringStudentRecord) -> some View {
        let isConnected = currentConnectedNameKeys.contains(student.nameKey)

        Text(isConnected ? "Connected" : "Disconnected")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background((isConnected ? Color.green : Color.red).opacity(0.15))
            .foregroundStyle(isConnected ? Color.green : Color.red)
            .clipShape(Capsule())
    }

    private func lastActiveText(for student: ProctoringStudentRecord) -> String {
        guard let lastActiveAt = student.lastActiveAt else {
            return "Last active: -"
        }

        return "Last active: \(studentLastActiveFormatter.string(from: lastActiveAt))"
    }

    private var currentConnectedNameKeys: Set<String> {
        Set(
            store.sentinelList
                .map { normalizedDisplayName(name: $0.name, sentinelId: $0.sentinelId) }
                .map { ProctoringPreferencesStore.normalizeName($0) }
                .filter { !$0.isEmpty }
        )
    }

    private func toggleFavourite(for student: ProctoringStudentRecord) {
        if selectedNameKeys.contains(student.nameKey) {
            selectedNameKeys.remove(student.nameKey)
        } else {
            selectedNameKeys.insert(student.nameKey)
        }
    }

    private func normalizedDisplayName(name: String?, sentinelId: String) -> String {
        let trimmedName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? sentinelId : trimmedName
    }
}

private let studentLastActiveFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
}()
