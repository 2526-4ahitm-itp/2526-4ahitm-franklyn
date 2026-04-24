import SwiftUI

struct ProctoringFavouritesView: View {
    let examTitle: String
    let students: [ProctoringStudentRecord]

    @Binding var selectedIds: Set<String>

    var body: some View {
        List(sortedStudents, selection: $selectedIds) { student in
            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.body)
                Text(student.sentinelId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .navigationTitle("Favourites")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
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
                Text("Selected")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(selectedIds.count)")
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
}
