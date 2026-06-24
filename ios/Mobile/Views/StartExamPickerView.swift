import SwiftUI

struct StartExamPickerView: View {
    @Environment(ExamStore.self) private var store
    @EnvironmentObject private var loginService: LoginService

    let onStart: (ProctoringRoute) -> Void

    @State private var showCreateSheet = false

    var body: some View {
        List {
            if store.scheduledExams.isEmpty && !store.isLoading {
                ContentUnavailableView(
                    "No Scheduled Exams",
                    systemImage: "calendar.badge.plus",
                    description: Text("Create an exam to start proctoring.")
                )
            } else {
                ForEach(store.scheduledExams) { exam in
                    Button {
                        Task {
                            await store.startExam(id: exam.id)
                            guard let started = store.exams.first(where: { $0.id == exam.id }) else { return }
                            onStart(ProctoringRoute(
                                examId: started.id,
                                examTitle: started.title,
                                examPin: started.pin
                            ))
                        }
                    } label: {
                        ExamRowView(exam: exam)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Start Exam")
        .refreshable {
            await store.fetchExams()
        }
        .overlay {
            if store.isLoading && store.exams.isEmpty {
                ProgressView("Loading exams...")
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                Button {
                    showCreateSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Exam")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .foregroundStyle(.white)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showCreateSheet, onDismiss: {
            Task {
                await store.fetchExams()
            }
        }) {
            CreateExamView()
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
