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
            }
        }
        .onChange(of: store.liveExams.count) { _, newCount in
            if newCount <= 1 {
                navPath = NavigationPath()
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
        } else if store.liveExams.isEmpty {
            StartExamPickerView { route in
                if store.liveExams.count > 1 {
                    navPath.append(route)
                }
            }
        } else {
            // ponytail: show ProctoringDashboardView directly as root when exactly one live exam is running
            let exam = store.liveExams[0]
            ProctoringDashboardView(
                examId: exam.id,
                examTitle: exam.title,
                examPin: exam.pin
            )
        }
    }
}
