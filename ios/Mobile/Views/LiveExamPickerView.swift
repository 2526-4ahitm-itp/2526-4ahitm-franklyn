import SwiftUI

struct LiveExamPickerView: View {
    @Environment(ExamStore.self) private var store

    var body: some View {
        List {
            ForEach(store.liveExams) { exam in
                NavigationLink(value: ProctoringRoute(
                    examId: exam.id,
                    examTitle: exam.title,
                    examPin: exam.pin
                )) {
                    ExamRowView(exam: exam)
                }
            }
        }
        .navigationTitle("Live Tests")
        .refreshable {
            await store.fetchExams()
        }
        .overlay {
            if store.liveExams.isEmpty && !store.isLoading {
                ContentUnavailableView(
                    "No Live Tests",
                    systemImage: "clock",
                    description: Text("No exams are currently live.")
                )
            }
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
}
