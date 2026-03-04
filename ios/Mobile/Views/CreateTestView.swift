import SwiftUI

struct CreateTestView: View {
    @Environment(TestStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var scheduleStart = false
    @State private var startTime = Date()
    @State private var accountPrefix = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Test Info") {
                    TextField("Test Title", text: $title)

                    TextField("Account Prefix (optional)", text: $accountPrefix)
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
            .navigationTitle("New Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        isSaving = true
                        Task {
                            await store.createTest(
                                title: title,
                                startTime: scheduleStart ? startTime : nil,
                                testAccountPrefix: accountPrefix.isEmpty ? nil : accountPrefix
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
