import SwiftUI

struct ExamListView: View {
    @Environment(ExamStore.self) private var store
    @EnvironmentObject private var loginService: LoginService

    @State private var showCreateSheet = false
    
    var onProfileTapped: (() -> Void)?

    var body: some View {
        List {
            if !store.liveExams.isEmpty {
                Section("Live") {
                    ForEach(store.liveExams) { exam in
                        NavigationLink(value: exam.id) {
                            ExamRowView(exam: exam)
                        }
                    }
                    .onDelete { offsets in
                        deleteExams(from: store.liveExams, at: offsets)
                    }
                }
            }

            if !store.scheduledExams.isEmpty {
                Section("Scheduled") {
                    ForEach(store.scheduledExams) { exam in
                        NavigationLink(value: exam.id) {
                            ExamRowView(exam: exam)
                        }
                    }
                    .onDelete { offsets in
                        deleteExams(from: store.scheduledExams, at: offsets)
                    }
                }
            }

            if !store.completedExams.isEmpty {
                Section("Completed") {
                    ForEach(store.completedExams) { exam in
                        NavigationLink(value: exam.id) {
                            ExamRowView(exam: exam)
                        }
                    }
                    .onDelete { offsets in
                        deleteExams(from: store.completedExams, at: offsets)
                    }
                }
            }

            if store.exams.isEmpty && !store.isLoading {
                ContentUnavailableView(
                    "No Exams",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Create a new exam to get started.")
                )
            }
        }
        .navigationTitle("Exams")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onProfileTapped?()
                } label: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .refreshable {
            await store.fetchExams()
        }
        .task(id: loginService.isLoggedIn) {
            if loginService.isLoggedIn {
                await store.fetchExams()
            }
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

    private func deleteExams(from section: [FrExam], at offsets: IndexSet) {
        for offset in offsets {
            let exam = section[offset]
            Task {
                await store.deleteExam(id: exam.id)
            }
        }
    }
}

// MARK: - Row

struct ExamRowView: View {
    let exam: FrExam

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exam.title)
                    .font(.headline)
                Spacer()
                ExamStateBadge(state: exam.state)
            }

            HStack(spacing: 8) {
                if let pin = exam.pin {
                    Text("PIN \(String(pin))")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                } else {
                    Text("PIN N/A")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                Text("·")
                    .foregroundStyle(.tertiary)
                    .font(.caption)

                if let start = exam.startTime {
                    if let end = exam.endTime {
                        Text("\(start.formatted(.dateTime.month(.abbreviated).day())) · \(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(start.formatted(.dateTime.month(.abbreviated).day())) · \(start.formatted(date: .omitted, time: .shortened)) – now")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Not scheduled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - State Badge

struct ExamStateBadge: View {
    let state: FrExam.State

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch state {
        case .live: "Live"
        case .scheduled: "Scheduled"
        case .completed: "Completed"
        }
    }

    private var color: Color {
        switch state {
        case .live: .green
        case .scheduled: .blue
        case .completed: .secondary
        }
    }
}
