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
