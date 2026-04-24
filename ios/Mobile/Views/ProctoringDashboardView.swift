import SwiftUI
import UIKit

struct ProctoringSentinelIdWrapper: Identifiable {
    let id: String
}

struct ProctoringDashboardView: View {
    @State private var store = WebsocketStore.shared
    @State private var seenStudents: [ProctoringStudentRecord] = []
    @State private var favouriteStudentNameKeys = Set<String>()

    let examId: String
    let examTitle: String
    let examPin: Int?

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 12) {
                    overviewNavigationCard
                    timelineNavigationCard
                }
                .padding(16)
            }
        }
        .navigationTitle("Proctoring")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ProctoringFavouritesView(
                        examTitle: examTitle,
                        students: seenStudents,
                        selectedNameKeys: $favouriteStudentNameKeys
                    )
                } label: {
                    Label("Favourites", systemImage: "checklist")
                }
            }
        }
        .onAppear {
            loadPersistedStudents()
            store.enterProctoringScope(pin: examPin)
        }
        .onDisappear {
            store.exitProctoringScope()
        }
        .onChange(of: sentinelListSignature) {
            mergeCurrentConnectedStudentsIntoHistory()
        }
        .onChange(of: favouriteStudentNameKeys) {
            ProctoringPreferencesStore.shared.setFavouriteStudentNameKeys(favouriteStudentNameKeys, for: examId)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(examTitle)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 8) {
                if let examPin {
                    Text("PIN \(String(examPin))")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text("PIN N/A")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Text("ID \(examId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 0)

                Text("Favourites \(favouriteStudentNameKeys.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var overviewNavigationCard: some View {
        NavigationLink {
            ProctoringOverviewListView()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overview")
                        .font(.headline)
                    Text(actualConnectedCount == 1 ? "Student participating" : "Students participating")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(actualConnectedCount)/\(allTimeCount)")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.monospaced)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var timelineNavigationCard: some View {
        NavigationLink {
            ProctoringTimelineView()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Timeline")
                        .font(.headline)
                    if let latest = latestTimelineEvent {
                        Text("\(timelineTimeFormatter.string(from: latest.timestamp)) · \(eventLabel(for: latest.type))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("No activity yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(store.timelineEvents.count)")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.monospaced)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.14))
                    .clipShape(Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var sentinelListSignature: String {
        store.sentinelList
            .map { "\($0.sentinelId)|\($0.name ?? "")" }
            .sorted()
            .joined(separator: "||")
    }

    private var actualConnectedCount: Int {
        Set(store.sentinelList.map { normalizedDisplayName(name: $0.name, sentinelId: $0.sentinelId) }).count
    }

    private var allTimeCount: Int {
        seenStudents.count
    }

    private func loadPersistedStudents() {
        seenStudents = ProctoringPreferencesStore.shared.seenStudents(for: examId)
        favouriteStudentNameKeys = ProctoringPreferencesStore.shared.favouriteStudentNameKeys(for: examId)
        mergeCurrentConnectedStudentsIntoHistory()
    }

    private func mergeCurrentConnectedStudentsIntoHistory() {
        let currentStudents = store.sentinelList.map {
            ProctoringStudentRecord(name: normalizedDisplayName(name: $0.name, sentinelId: $0.sentinelId))
        }

        guard !currentStudents.isEmpty else { return }

        ProctoringPreferencesStore.shared.mergeSeenStudents(currentStudents, for: examId)
        seenStudents = ProctoringPreferencesStore.shared.seenStudents(for: examId)
    }

    private func normalizedDisplayName(name: String?, sentinelId: String) -> String {
        let trimmedName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? sentinelId : trimmedName
    }

    private var latestTimelineEvent: ProctoringTimelineEvent? {
        store.timelineEvents.last
    }

    private func eventLabel(for type: ProctoringTimelineEventType) -> String {
        switch type {
        case .joined: return "Joined"
        case .left: return "Left"
        case .rejoined: return "Rejoined"
        case .connectionLost: return "Connection lost"
        case .backOnline: return "Back online"
        }
    }
}

private let timelineTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
}()

struct ProctoringOverviewListView: View {
    @State private var store = WebsocketStore.shared
    @State private var selectedSentinel: ProctoringSentinelIdWrapper?

    var body: some View {
        List {
            if sentinelIds.isEmpty {
                Text("No sentinels connected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sentinelIds, id: \.self) { sentinelId in
                    Button {
                        selectedSentinel = ProctoringSentinelIdWrapper(id: sentinelId)
                    } label: {
                        ProctoringOverviewRow(
                            name: store.sentinelName(for: sentinelId) ?? sentinelId,
                            image: store.framesBySentinel[sentinelId]
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Overview")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.enterProctoringScope(pin: nil)
            store.enableSubscribeAllMode()
        }
        .onDisappear {
            store.disableSubscribeAllMode()
            store.exitProctoringScope()
        }
        .fullScreenCover(item: $selectedSentinel) { sentinel in
            ProctoringFullscreenView(
                sentinelId: sentinel.id,
                name: store.sentinelName(for: sentinel.id) ?? sentinel.id,
                image: store.framesBySentinel[sentinel.id],
                onDismiss: { selectedSentinel = nil }
            )
        }
    }

    private var sentinelIds: [String] {
        store.sentinelList
            .map(\.sentinelId)
            .sorted {
                let lhsName = store.sentinelName(for: $0) ?? $0
                let rhsName = store.sentinelName(for: $1) ?? $1
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }
    }
}

struct ProctoringTimelineView: View {
    @State private var store = WebsocketStore.shared

    var body: some View {
        List {
            if store.hadConnectionInstability {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Connection was unstable. Some events may have appeared with a short delay.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.orange.opacity(0.08))
            }

            if timelineEventsNewestFirst.isEmpty {
                Text("No activity yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(timelineEventsNewestFirst) { event in
                    ProctoringTimelineRow(event: event)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.enterProctoringScope(pin: nil)
        }
        .onDisappear {
            store.exitProctoringScope()
        }
    }

    private var timelineEventsNewestFirst: [ProctoringTimelineEvent] {
        store.timelineEvents.reversed()
    }
}

struct ProctoringTimelineRow: View {
    let event: ProctoringTimelineEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(eventColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(event.studentName) \(eventActionText)")
                    .font(.body)
                Text(timelineTimeFormatter.string(from: event.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var eventActionText: String {
        switch event.type {
        case .joined: return "joined"
        case .left: return "left"
        case .rejoined: return "rejoined"
        case .connectionLost: return "had a connection issue"
        case .backOnline: return "is back online"
        }
    }

    private var eventColor: Color {
        switch event.type {
        case .joined: return .green
        case .left: return .red
        case .rejoined: return .orange
        case .connectionLost: return .red
        case .backOnline: return .green
        }
    }
}

struct ProctoringOverviewRow: View {
    let name: String
    let image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(name)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)

            ZStack {
                Color.black.opacity(0.05)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                } else {
                    Image(systemName: "video.slash")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ProctoringSentinelCard: View {
    let name: String
    let image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color.black.opacity(0.05)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    Image(systemName: "video.slash")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct ProctoringFullscreenView: View {
    let sentinelId: String
    let name: String
    let image: UIImage?
    let onDismiss: () -> Void

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if verticalSizeClass == .compact {
                landscapeView
            } else {
                portraitView
            }
        }
        .statusBar(hidden: true)
    }

    private var portraitView: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Close") {
                    onDismiss()
                }
                .foregroundColor(.white)
                .padding()

                Spacer()

                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.top, 40)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(8)
            }

            Spacer()
        }
    }

    private var landscapeView: some View {
        let scaleFactor = 0.93

        return VStack(spacing: 0) {
            HStack {
                Button("Close") {
                    onDismiss()
                }
                .foregroundColor(.white)
                .padding()

                Spacer()

                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.top, 40)
            .scaleEffect(scaleFactor)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        maxWidth: UIScreen.main.bounds.width * scaleFactor,
                        maxHeight: UIScreen.main.bounds.height * scaleFactor
                    )
                    .clipped()
            }
        }
    }
}
