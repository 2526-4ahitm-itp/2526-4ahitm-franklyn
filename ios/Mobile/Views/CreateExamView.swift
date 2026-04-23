import SwiftUI

struct CreateExamView: View {
    @Environment(ExamStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var scheduleStart = false
    @State private var startTime = Date()
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Exam Info") {
                    TextField("Exam Title", text: $title)
                }

                Section("Schedule") {
                    Toggle("Schedule Start Time", isOn: $scheduleStart)

                    if scheduleStart {
                        DatePicker(
                            "Start Time",
                            selection: $startTime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
            }
            .navigationTitle("New Exam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        isSaving = true
                        Task {
                            await store.createExam(
                                title: title,
                                startTime: scheduleStart ? startTime : nil
                            )
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }
}
