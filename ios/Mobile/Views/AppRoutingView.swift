import SwiftUI

struct ProctoringRoute: Hashable {
    let examId: String
    let examTitle: String
    let examPin: Int?
}

struct AppRoutingView: View {
    @Environment(ExamStore.self) private var store
    @EnvironmentObject private var loginService: LoginService
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            routeRoot
                .navigationDestination(for: String.self) { examId in
                    ExamDetailView(examId: examId)
                }
                .navigationDestination(for: ProctoringRoute.self) { route in
                    ProctoringDashboardView(
                        examId: route.examId,
                        examTitle: route.examTitle,
                        examPin: route.examPin
                    )
                }
        }
        .task(id: loginService.isLoggedIn) {
            if loginService.isLoggedIn {
                await store.fetchExams()
                autoRouteIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var routeRoot: some View {
        if store.isLoading && store.exams.isEmpty {
            ProgressView("Loading...")
                .navigationTitle("Exams")
        } else if store.liveExams.count > 1 {
            LiveExamPickerView()
        } else {
            ExamListView()
        }
    }

    private func autoRouteIfNeeded() {
        guard navPath.isEmpty, store.liveExams.count == 1 else { return }
        let exam = store.liveExams[0]
        navPath.append(ProctoringRoute(examId: exam.id, examTitle: exam.title, examPin: exam.pin))
    }
}
