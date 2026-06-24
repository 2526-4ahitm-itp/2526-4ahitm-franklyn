import SwiftUI

struct ProctoringStudentListView: View {
    let students: [ProctoringStudentRecord]
    let examPin: Int?

    @Binding var selectedNameKeys: Set<String>
    @State private var store = WebsocketStore.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color(white: 0.15))
                        .clipShape(Circle())
                }

                Spacer()

                Text("Students")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Balance back button to center the title
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 20)

            // ponytail: simplified list using ScrollView and Custom Section Cards instead of system List styling.
            ScrollView {
                VStack(spacing: 24) {
                    if !offlineStudents.isEmpty {
                        studentSection(title: "\(offlineStudents.count) offline", students: offlineStudents, isOnline: false)
                    }

                    if !onlineStudents.isEmpty {
                        studentSection(title: "\(onlineStudents.count) online", students: onlineStudents, isOnline: true)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .overlay {
            if students.isEmpty {
                ContentUnavailableView(
                    "No Students Yet",
                    systemImage: "person.2.slash",
                    description: Text("Students will appear here after they connect to this exam.")
                )
            }
        }
        .onAppear {
            store.enterProctoringScope(pin: examPin)
        }
        .onDisappear {
            store.exitProctoringScope()
        }
    }

    private var sortedStudents: [ProctoringStudentRecord] {
        // ponytail: sort by activity freshness first, then alphabetical fallback to match screenshot ordering.
        students.sorted {
            if let firstDate = $0.lastActiveAt, let secondDate = $1.lastActiveAt {
                return firstDate > secondDate
            }
            if $0.lastActiveAt != nil { return true }
            if $1.lastActiveAt != nil { return false }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var onlineStudents: [ProctoringStudentRecord] {
        sortedStudents.filter { currentConnectedNameKeys.contains($0.nameKey) }
    }

    private var offlineStudents: [ProctoringStudentRecord] {
        sortedStudents.filter { !currentConnectedNameKeys.contains($0.nameKey) }
    }

    private func studentSection(title: String, students: [ProctoringStudentRecord], isOnline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.leading, 8)

            VStack(spacing: 0) {
                ForEach(Array(students.enumerated()), id: \.element.id) { index, student in
                    studentRow(student: student, isOnline: isOnline)

                    if index < students.count - 1 {
                        Divider()
                            .background(Color(white: 0.2))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(white: 0.11))
            .cornerRadius(16)
        }
    }

    private func studentRow(student: ProctoringStudentRecord, isOnline: Bool) -> some View {
        Button {
            toggleFavourite(for: student)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: isOnline ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 20))
                    .foregroundColor(isOnline ? .green : .red)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(student.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(lastActiveText(for: student))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: selectedNameKeys.contains(student.nameKey) ? "star.fill" : "star")
                    .font(.system(size: 22))
                    .foregroundColor(selectedNameKeys.contains(student.nameKey) ? .orange : Color(white: 0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
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
