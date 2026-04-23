import SwiftUI

struct ExamDetailView: View {
    @Environment(ExamStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let examId: String

    private var exam: FrExam? {
        store.exams.first { $0.id == examId }
    }

    var body: some View {
        Group {
            if let exam {
                List {
                    Section("Overview") {
                        DetailRow(label: "Title", value: exam.title)
                        DetailRow(label: "Status", value: stateLabel(exam.state))
                        if let teacherId = exam.teacherId {
                            DetailRow(label: "Teacher ID", value: teacherId)
                        }
                    }

                    Section("Schedule") {
                        DetailRow(
                            label: "Scheduled Start",
                            value: exam.startTime?.formatted(date: .abbreviated, time: .shortened) ?? "Not set"
                        )
                        DetailRow(
                            label: "Actual Start",
                            value: exam.startedAt?.formatted(date: .abbreviated, time: .shortened) ?? "-"
                        )
                        DetailRow(
                            label: "Scheduled End",
                            value: exam.endTime?.formatted(date: .abbreviated, time: .shortened) ?? "Not set"
                        )
                        DetailRow(
                            label: "Actual End",
                            value: exam.endedAt?.formatted(date: .abbreviated, time: .shortened) ?? "-"
                        )
                    }

                    Section {
                        switch exam.state {
                        case .scheduled:
                            Button("Start Exam") {
                                Task { await store.startExam(id: exam.id) }
                            }
                            .tint(.green)

                        case .live:
                            Button("End Exam") {
                                Task { await store.endExam(id: exam.id) }
                            }
                            .tint(.orange)

                        case .completed:
                            Text("This exam is completed.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Button("Delete Exam", role: .destructive) {
                            Task {
                                let deleted = await store.deleteExam(id: exam.id)
                                if deleted {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .navigationTitle(exam.title)
            } else {
                ContentUnavailableView(
                    "Exam Not Found",
                    systemImage: "questionmark.folder"
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .init(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private func stateLabel(_ state: FrExam.State) -> String {
        switch state {
        case .live: "Live"
        case .scheduled: "Scheduled"
        case .completed: "Completed"
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
