import SwiftUI
import UIKit

struct ProctoringSentinelIdWrapper: Identifiable {
    let id: String
}

struct ProctoringDashboardView: View {
    @State private var store = WebsocketStore.shared
    @State private var seenStudents: [ProctoringStudentRecord] = []
    @State private var favouriteStudentNameKeys = Set<String>()
    @State private var previousConnectedStudentsByKey: [String: String] = [:]

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
                    ProctoringStudentListView(
                        students: seenStudents,
                        examPin: examPin,
                        selectedNameKeys: $favouriteStudentNameKeys
                    )
                } label: {
                    Label("Students", systemImage: "person.2")
                }
            }
        }
        .onAppear {
            loadPersistedStudents()
            previousConnectedStudentsByKey = currentConnectedStudentsByKey
            store.enterProctoringScope(pin: examPin)
        }
        .onDisappear {
            store.exitProctoringScope()
        }
        .onChange(of: sentinelListSignature) {
            syncStudentHistoryFromConnectionState()
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
                        Text("\(latest.studentName) \(eventAction(for: latest.type)) at \(timelineTimeFormatter.string(from: latest.timestamp))")
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
        syncStudentHistoryFromConnectionState()
    }

    private func syncStudentHistoryFromConnectionState() {
        let now = Date()
        let currentByKey = currentConnectedStudentsByKey
        let removedKeys = Set(previousConnectedStudentsByKey.keys).subtracting(Set(currentByKey.keys))

        if !removedKeys.isEmpty {
            let removedNames = removedKeys.compactMap { previousConnectedStudentsByKey[$0] }
            ProctoringPreferencesStore.shared.markLastActive(for: removedNames, at: now, examId: examId)
        }

        let currentStudents = currentByKey.values.map { ProctoringStudentRecord(name: $0, lastActiveAt: now) }

        if !currentStudents.isEmpty {
            ProctoringPreferencesStore.shared.mergeSeenStudents(currentStudents, for: examId, activeAt: now)
        }

        seenStudents = ProctoringPreferencesStore.shared.seenStudents(for: examId)
        previousConnectedStudentsByKey = currentByKey
    }

    private func normalizedDisplayName(name: String?, sentinelId: String) -> String {
        let trimmedName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? sentinelId : trimmedName
    }

    private var latestTimelineEvent: ProctoringTimelineEvent? {
        store.timelineEvents.last
    }

    private var currentConnectedStudentsByKey: [String: String] {
        var map: [String: String] = [:]

        for sentinel in store.sentinelList {
            let name = normalizedDisplayName(name: sentinel.name, sentinelId: sentinel.sentinelId)
            let key = ProctoringPreferencesStore.normalizeName(name)

            guard !key.isEmpty else { continue }
            map[key] = name
        }

        return map
    }

    private func eventLabel(for type: ProctoringTimelineEventType) -> String {
        switch type {
        case .joined: return "Joined"
        case .left: return "Left"
        case .rejoined: return "Rejoined"
        }
    }

    private func eventAction(for type: ProctoringTimelineEventType) -> String {
        switch type {
        case .joined: return "joined"
        case .left: return "left"
        case .rejoined: return "rejoined"
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
        }
    }

    private var eventColor: Color {
        switch event.type {
        case .joined: return .green
        case .left: return .red
        case .rejoined: return .orange
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

    @State private var controlsVisible = true
    @State private var controlsHideTask: Task<Void, Never>?
    @State private var didForceLandscape = false

    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.width < geometry.size.height
            let safeArea = geometry.safeAreaInsets
            
            ZStack {
                Color.black.ignoresSafeArea()
    
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(
                            isPortrait
                            ? EdgeInsets(top: safeArea.trailing, leading: safeArea.top, bottom: safeArea.leading, trailing: safeArea.bottom)
                            : EdgeInsets(top: safeArea.top, leading: safeArea.leading, bottom: safeArea.bottom, trailing: safeArea.trailing)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Image(systemName: "video.slash")
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.7))
                }
    
                if controlsVisible {
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [Color.black.opacity(0.75), Color.black.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 140)
                        .overlay(alignment: .top) {
                            HStack(spacing: 12) {
                                Button {
                                    onDismiss()
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                }
    
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
    
                                    Text("Live · \(sentinelId)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.75))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
    
                                Spacer()
                            }
                            .padding(.top, 24)
                            .padding(.horizontal, 48)
                        }
    
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                revealControls()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { _ in revealControls() }
                    .onEnded { _ in scheduleControlsAutoHide() }
            )
            .frame(
                width: isPortrait ? geometry.size.height : geometry.size.width,
                height: isPortrait ? geometry.size.width : geometry.size.height
            )
            .rotationEffect(.degrees(isPortrait ? 90 : 0))
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
        .ignoresSafeArea()
        .onAppear {
            scheduleControlsAutoHide()
        }
        .onDisappear {
            controlsHideTask?.cancel()
        }
        .statusBar(hidden: true)
    }

    private func revealControls() {
        guard !controlsVisible else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            controlsVisible = true
        }
        scheduleControlsAutoHide()
    }

    private func hideControls() {
        controlsHideTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            controlsVisible = false
        }
    }

    private func scheduleControlsAutoHide() {
        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    controlsVisible = false
                }
            }
        }
    }
}
