import SwiftUI

struct CreateExamView: View {
    @Environment(ExamStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var examDate = Date()
    @State private var startClock = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endClock = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var isSaving = false
    @State private var localError: String?

    private var combinedStart: Date {
        combine(date: examDate, time: startClock)
    }

    private var combinedEnd: Date {
        combine(date: examDate, time: endClock)
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && combinedEnd > combinedStart
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exam Info") {
                    TextField("Exam Title", text: $title)
                }

                Section("Schedule") {
                    DatePicker(
                        "Date",
                        selection: $examDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Start Time",
                        selection: $startClock,
                        displayedComponents: .hourAndMinute
                    )
                    DatePicker(
                        "End Time",
                        selection: $endClock,
                        displayedComponents: .hourAndMinute
                    )

                    if combinedEnd <= combinedStart {
                        Text("End time must be after start time.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                if let error = localError ?? store.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
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
                        localError = nil
                        store.errorMessage = nil
                        guard combinedEnd > combinedStart else {
                            localError = "End time must be after start time."
                            return
                        }

                        isSaving = true
                        Task {
                            let created = await store.createExam(
                                title: title,
                                startTime: combinedStart,
                                endTime: combinedEnd
                            )
                            isSaving = false

                            if created != nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
        }
    }

    private func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        return calendar.date(
            from: DateComponents(
                year: dateComponents.year,
                month: dateComponents.month,
                day: dateComponents.day,
                hour: timeComponents.hour,
                minute: timeComponents.minute
            )
        ) ?? date
    }
}
