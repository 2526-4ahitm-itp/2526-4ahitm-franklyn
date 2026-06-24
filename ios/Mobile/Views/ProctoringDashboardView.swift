import Combine
import SwiftUI
import UIKit

struct ProctoringSentinelIdWrapper: Identifiable {
    let id: String
}

// MARK: - Dashboard

struct ProctoringDashboardView: View {
    @State private var store = WebsocketStore.shared
    @Environment(ExamStore.self) private var examStore
    @Environment(\.dismiss) private var dismiss

    @State private var now = Date()
    @State private var showEndConfirmation = false
    @State private var isEndingExam = false
    @State private var favouriteNameKeys: Set<String> = []
    @State private var seenStudents: [ProctoringStudentRecord] = []
    @State private var favouritesLoaded = false

    let examId: String
    let examTitle: String
    let examPin: Int?

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Computed exam data

    private var exam: FrExam? {
        examStore.exams.first { $0.id == examId }
    }

    private var scheduledEnd: Date? { exam?.endTime }
    private var actualStart: Date? { exam?.startedAt }

    // MARK: - Timer state

    private var isOvertime: Bool {
        guard let end = scheduledEnd else { return false }
        return now >= end
    }

    private var countdownRemaining: TimeInterval {
        guard let end = scheduledEnd else { return 0 }
        return max(0, end.timeIntervalSince(now))
    }

    private var overtimeElapsed: TimeInterval {
        guard let end = scheduledEnd else { return 0 }
        return max(0, now.timeIntervalSince(end))
    }

    private var scheduledDuration: TimeInterval {
        guard let start = actualStart, let end = scheduledEnd else { return 3600 }
        return max(1, end.timeIntervalSince(start))
    }

    private var elapsedSinceStart: TimeInterval {
        guard let start = actualStart else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    private var countdownProgress: Double {
        guard scheduledDuration > 0 else { return 0 }
        return min(1, elapsedSinceStart / scheduledDuration)
    }

    // Three-zone bar fractions for overtime. zone3 floored at 12%.
    private var overtimeBarFractions: (z1: Double, z2: Double, z3: Double) {
        let S = scheduledDuration
        let T = overtimeElapsed
        let R = 0.25 * S
        let total = S + T + R
        guard total > 0 else { return (0.88, 0, 0.12) }

        var z1 = S / total
        var z2 = T / total
        var z3 = R / total

        if z3 < 0.12 {
            let deficit = 0.12 - z3
            z3 = 0.12
            let sum12 = z1 + z2
            if sum12 > 0 {
                z1 -= deficit * z1 / sum12
                z2 -= deficit * z2 / sum12
            }
        }

        return (z1, z2, z3)
    }

    // MARK: - Student stats

    private var presentCount: Int {
        Set(store.sentinelList.map { resolvedName(name: $0.name, sentinelId: $0.sentinelId) }).count
    }

    private var studentNetStates: [String: ProctoringTimelineEventType] {
        var map: [String: ProctoringTimelineEventType] = [:]
        for event in store.timelineEvents { map[event.studentName] = event.type }
        return map
    }

    private var leftCount: Int {
        studentNetStates.values.filter { $0 == .left }.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            ScrollView {
                VStack(spacing: 16) {
                    timerCard
                    studentsCard
                    favouritesCard
                    screensCard
                    chatCard
                    examInfoCard
                }
                .padding(16)

                endExamButton
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.enterProctoringScope(pin: examPin)
            let prefs = ProctoringPreferencesStore.shared
            // Always merge the current sentinel list so seenStudents is never stale
            let records = store.sentinelList.compactMap { sentinel -> ProctoringStudentRecord? in
                let name = (sentinel.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, UUID(uuidString: name) == nil else { return nil }
                return ProctoringStudentRecord(name: name)
            }
            prefs.mergeSeenStudents(records, for: examId)
            seenStudents = prefs.seenStudents(for: examId)
            // Load favourites only once — binding keeps them in sync after that
            if !favouritesLoaded {
                favouriteNameKeys = prefs.favouriteStudentNameKeys(for: examId)
                favouritesLoaded = true
            }
        }
        .onDisappear {
            store.exitProctoringScope()
        }
        .onReceive(ticker) { now = $0 }
        .onChange(of: store.sentinelList.map(\.sentinelId)) {
            let records = store.sentinelList.compactMap { sentinel -> ProctoringStudentRecord? in
                let name = (sentinel.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, UUID(uuidString: name) == nil else { return nil }
                return ProctoringStudentRecord(name: name)
            }
            let prefs = ProctoringPreferencesStore.shared
            prefs.mergeSeenStudents(records, for: examId)
            seenStudents = prefs.seenStudents(for: examId)
        }
        .onChange(of: favouriteNameKeys) { _, newKeys in
            ProctoringPreferencesStore.shared.setFavouriteStudentNameKeys(newKeys, for: examId)
        }
        .alert("End Exam?", isPresented: $showEndConfirmation) {
            Button("End Exam", role: .destructive) {
                Task {
                    isEndingExam = true
                    await examStore.endExam(id: examId)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will end the exam for all students.")
        }
    }

    // MARK: - Title bar

    private var titleBar: some View {
        HStack(spacing: 12) {
            Text(examTitle)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(0)

            Spacer(minLength: 8)

            if let pin = examPin {
                Text(String(pin))
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
                    .layoutPriority(1)
            }

            NavigationLink {
                ProctoringStudentListView(
                    students: seenStudents,
                    examPin: examPin,
                    selectedNameKeys: $favouriteNameKeys
                )
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .overlay(alignment: .topTrailing) {
                        if presentCount > 0 {
                            Text("\(presentCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.red, in: Capsule())
                                .offset(x: 6, y: -6)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - Timer card

    private var timerCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                // Reserve width for "+" in both modes to prevent layout shift on transition.
                Text("+")
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.accentColor)
                    .opacity(isOvertime ? 1 : 0)

                Text(formatTime(isOvertime ? overtimeElapsed : countdownRemaining))
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isOvertime ? Color.accentColor : Color.primary)
                    .monospacedDigit()
            }

            Text(isOvertime ? "overtime" : "remaining")
                .font(.caption.weight(.medium))
                .foregroundStyle(isOvertime ? Color.accentColor : Color.secondary)

            timerProgressBar
                .padding(.top, 2)

            if let end = scheduledEnd {
                if isOvertime {
                    HStack(spacing: 0) {
                        Text("past scheduled end")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor)
                        Spacer(minLength: 0)
                        Text("ended \(formatHHMM(end))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("ends \(formatHHMM(end))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isOvertime ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.25), value: isOvertime)
    }

    @ViewBuilder
    private var timerProgressBar: some View {
        GeometryReader { geo in
            let bw = geo.size.width

            if isOvertime {
                let frac = overtimeBarFractions
                let w1 = CGFloat(frac.z1) * bw
                let w2 = CGFloat(frac.z2) * bw

                ZStack(alignment: .leading) {
                    // Track
                    Color(uiColor: .systemFill)
                        .frame(width: bw, height: 6)
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    // Zone 1 (scheduled elapsed) + Zone 2 (overtime) + Zone 3 (empty via Spacer)
                    HStack(spacing: 0) {
                        Color.secondary.opacity(0.35)
                            .frame(width: max(0, w1), height: 6)
                        Color.accentColor
                            .frame(width: max(0, w2), height: 6)
                        Spacer(minLength: 0)
                    }
                    .frame(width: bw, height: 6)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                    // End marker at zone1/zone2 boundary
                    Color.accentColor
                        .frame(width: 2, height: 14)
                        .offset(x: max(0, w1 - 1))
                }
                .frame(width: bw, height: 14)
            } else {
                ZStack(alignment: .leading) {
                    Color(uiColor: .systemFill)
                        .frame(width: bw, height: 6)
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    Color.secondary.opacity(0.35)
                        .frame(width: max(0, CGFloat(countdownProgress) * bw), height: 6)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .frame(width: bw, height: 14)
            }
        }
        .frame(height: 14)
        .animation(.easeInOut(duration: 0.25), value: isOvertime)
    }

    // MARK: - Favourites card

    private var favouritesCard: some View {
        NavigationLink {
            ProctoringFavouritesSlideView(
                students: seenStudents,
                favouriteNameKeys: favouriteNameKeys
            )
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("favourites")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 10)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(favouriteNameKeys.count) starred")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    if !favouriteNameKeys.isEmpty {
                        Text("tap to view slideshow")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("star students to track them here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(favouriteNameKeys.isEmpty)
    }

    // MARK: - Students card

    private var studentsCard: some View {
        NavigationLink {
            ProctoringTimelineView()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text("students")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("\(presentCount + leftCount) total")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 10)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(presentCount) present")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("\(leftCount) left")
                        .font(.subheadline)
                        .foregroundStyle(leftCount > 0 ? Color.orange : Color.secondary)
                }

                if let latest = store.timelineEvents.last {
                    Divider().padding(.vertical, 10)
                    latestEventFooter(latest)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func latestEventFooter(_ event: ProctoringTimelineEvent) -> some View {
        let isDeparture = event.type == .left
        HStack(spacing: 3) {
            Text("\(event.studentName) \(isDeparture ? "left" : "joined") · \(timeAgo(event.timestamp))")
                .font(.caption)
                .foregroundStyle(isDeparture ? Color.red : Color.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Screens card

    private var screensCard: some View {
        NavigationLink {
            ProctoringOverviewListView()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("screens")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                if !store.sentinelList.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(Array(store.sentinelList.prefix(3)), id: \.sentinelId) { sentinel in
                            screenThumbnail(for: sentinel)
                        }
                        Spacer(minLength: 0)
                    }
                }

                let count = store.sentinelList.count
                Text("\(count) screen\(count == 1 ? "" : "s") · tap to browse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func screenThumbnail(for sentinel: SentinelInfo) -> some View {
        ZStack {
            Color.black.opacity(0.08)
            if let image = store.framesBySentinel[sentinel.sentinelId] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "video.slash")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 72, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: - Chat card

    private var chatCard: some View {
        NavigationLink {
            ExamChatView(examId: examId)
        } label: {
            HStack {
                Text("chat")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exam info card

    private var examInfoCard: some View {
        HStack(spacing: 0) {
            examInfoColumn(label: "started", value: actualStart.map(formatHHMM) ?? "--:--")
            Divider().frame(height: 32)
            examInfoColumn(label: "duration", value: formatDuration(scheduledDuration))
            Divider().frame(height: 32)
            examInfoColumn(label: "elapsed", value: formatDuration(elapsedSinceStart))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func examInfoColumn(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .fontDesign(.monospaced)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - End exam button

    private var endExamButton: some View {
        Button {
            showEndConfirmation = true
        } label: {
            Text("end exam")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isEndingExam)
    }

    // MARK: - Helpers

    private func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func formatHHMM(_ date: Date) -> String {
        let h = Calendar.current.component(.hour, from: date)
        let m = Calendar.current.component(.minute, from: date)
        return String(format: "%02d:%02d", h, m)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h == 0 { return "\(m)m" }
        return "\(h)h \(String(format: "%02d", m))m"
    }

    private func timeAgo(_ date: Date) -> String {
        let minutes = Int(now.timeIntervalSince(date) / 60)
        if minutes < 1 { return "just now" }
        if minutes == 1 { return "1 min ago" }
        return "\(minutes) min ago"
    }

    private func resolvedName(name: String?, sentinelId: String) -> String {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? sentinelId : trimmed
    }
}

// MARK: - Favourites Slideshow

struct ProctoringFavouritesSlideView: View {
    let students: [ProctoringStudentRecord]
    let favouriteNameKeys: Set<String>

    @State private var store = WebsocketStore.shared
    @State private var currentIndex: Int = 0
    @State private var autoAdvanceTask: Task<Void, Never>?
    @State private var controlsVisible = true
    @State private var controlsHideTask: Task<Void, Never>?

    private var favouritedStudents: [(name: String, image: UIImage?)] {
        students
            .filter { favouriteNameKeys.contains(
                ProctoringPreferencesStore.normalizeName($0.name)) }
            .map { record in
                let sentinel = store.sentinelList.first {
                    ProctoringPreferencesStore.normalizeName(
                        $0.name ?? "") == ProctoringPreferencesStore.normalizeName(record.name)
                }
                let image = sentinel.flatMap { store.framesBySentinel[$0.sentinelId] }
                return (name: record.name, image: image)
            }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if favouritedStudents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("No favourited students")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else {
                slideContent
                if controlsVisible { overlayControls }
            }
        }
        .navigationTitle("Favourites")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.enterProctoringScope(pin: nil)
            store.enableSubscribeAllMode()
            scheduleAutoAdvance()
            scheduleControlsAutoHide()
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
            controlsHideTask?.cancel()
            store.disableSubscribeAllMode()
            store.exitProctoringScope()
        }
        .contentShape(Rectangle())
        .onTapGesture { revealControls() }
        .statusBar(hidden: true)
    }

    // MARK: - Subviews

    private var slideContent: some View {
        let student = favouritedStudents[currentIndex]
        return Group {
            if let image = student.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: "video.slash")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .transition(.opacity)
    }

    private var overlayControls: some View {
        let students = favouritedStudents
        return VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.black.opacity(0.7), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 120)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(students[currentIndex].name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(currentIndex + 1) / \(students.count)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 56)
                .padding(.horizontal, 20)
            }

            Spacer()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.65)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 140)
            .overlay(alignment: .bottom) {
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        ForEach(students.indices, id: \.self) { i in
                            Circle()
                                .fill(i == currentIndex ? Color.white : Color.white.opacity(0.35))
                                .frame(width: i == currentIndex ? 8 : 6,
                                       height: i == currentIndex ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    HStack(spacing: 48) {
                        Button { advance(by: -1) } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        Button { advance(by: 1) } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Logic

    private func advance(by delta: Int) {
        let count = favouritedStudents.count
        guard count > 0 else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            currentIndex = (currentIndex + delta + count) % count
        }
        scheduleAutoAdvance()
        revealControls()
    }

    private func scheduleAutoAdvance() {
        autoAdvanceTask?.cancel()
        guard favouritedStudents.count > 1 else { return }
        autoAdvanceTask = Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentIndex = (currentIndex + 1) % favouritedStudents.count
                }
                scheduleAutoAdvance()
            }
        }
    }

    private func revealControls() {
        withAnimation(.easeInOut(duration: 0.2)) { controlsVisible = true }
        scheduleControlsAutoHide()
    }

    private func scheduleControlsAutoHide() {
        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) { controlsVisible = false }
            }
        }
    }
}

private let timelineTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
}()

// MARK: - Overview List

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

// MARK: - Timeline

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

            if store.timelineEvents.isEmpty {
                Text("No activity yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let individual = individualEventsNewestFirst
                let group = sessionStartGroup
                ForEach(Array(individual.enumerated()), id: \.element.id) { index, event in
                    ProctoringTimelineRow(
                        event: event,
                        hasLineBelow: index < individual.count - 1 || !group.isEmpty
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
                if !group.isEmpty {
                    SessionStartEntry(participants: group)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
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

    // Leading run of joins at session creation: scan oldest upward, keep adding
    // joins until a non-join event or a >5s gap between consecutive joins.
    private var sessionStartGroup: [ProctoringTimelineEvent] {
        let events = store.timelineEvents // oldest first
        var count = 0
        for i in events.indices {
            let e = events[i]
            if e.type != .joined { break }
            if i > 0, e.timestamp.timeIntervalSince(events[i - 1].timestamp) > 5 { break }
            count += 1
        }
        // ponytail: a lone join reads better as its own row; collapse only real bursts
        guard count >= 2 else { return [] }
        return Array(events.prefix(count))
    }

    private var individualEventsNewestFirst: [ProctoringTimelineEvent] {
        Array(store.timelineEvents.dropFirst(sessionStartGroup.count)).reversed()
    }
}

struct ProctoringTimelineRow: View {
    let event: ProctoringTimelineEvent
    var hasLineBelow: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            TimelineNodeColumn(
                color: eventColor,
                systemImage: eventIcon,
                hasLineBelow: hasLineBelow
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(event.studentName)
                    .font(.headline)
                Text(eventActionText)
                    .font(.subheadline)
                    .foregroundStyle(eventColor)
                Text(timelineTimeFormatter.string(from: event.timestamp))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 6)
            .padding(.bottom, 22)

            Spacer(minLength: 0)
        }
    }

    private var eventActionText: String {
        switch event.type {
        case .joined: return "Joined the session"
        case .left: return "Left the session"
        case .rejoined: return "Rejoined the session"
        }
    }

    private var eventIcon: String {
        switch event.type {
        case .joined: return "person.fill.badge.plus"
        case .left: return "person.fill.badge.minus"
        case .rejoined: return "person.fill.checkmark"
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

// Vertical connector + circular node shared by every timeline entry.
// Connector stops short of each node (gap) so it links nodes without
// running through them.
struct TimelineNodeColumn: View {
    let color: Color
    let systemImage: String
    var hasLineBelow: Bool = false
    var diameter: CGFloat = 38
    private let gap: CGFloat = 6

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color.clear.frame(height: diameter + gap) // node + gap after it
                Rectangle()
                    .fill(hasLineBelow ? lineColor : Color.clear)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                Color.clear.frame(height: gap)            // gap before next node
            }
            ZStack {
                Circle().fill(color.opacity(0.18))
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: diameter, height: diameter)
        }
        .frame(width: diameter)
    }

    private var lineColor: Color { Color.secondary.opacity(0.3) }
}

// Collapsed bottom entry for the participants present at session creation.
struct SessionStartEntry: View {
    let participants: [ProctoringTimelineEvent] // oldest first

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            TimelineNodeColumn(
                color: .green,
                systemImage: "person.2.fill",
                hasLineBelow: false
            )
            VStack(alignment: .leading, spacing: 3) {
                Text("Session started")
                    .font(.headline)
                Text("\(participants.count) participant\(participants.count == 1 ? "" : "s") joined")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                if let first = participants.first {
                    Text(timelineTimeFormatter.string(from: first.timestamp))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    ForEach(participants) { p in
                        TimelineParticipantRow(name: p.studentName)
                    }
                }
                .padding(.top, 12)
            }
            .padding(.top, 6)
            .padding(.bottom, 22)

            Spacer(minLength: 0)
        }
    }
}

struct TimelineParticipantRow: View {
    let name: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(avatarColor)
                Text(initials)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            Text(name)
                .font(.subheadline)
                .lineLimit(2)

            Spacer(minLength: 8)

            Text(role)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.secondary.opacity(0.15)))
        }
    }

    private var initials: String {
        let chars = name.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(chars).uppercased()
    }

    // ponytail: no role field on the wire; derive from the account name.
    // Replace with a real role on ProctoringTimelineEvent when the server sends one.
    private var role: String {
        let lower = name.lowercased()
        if lower.contains("admin") { return "admin" }
        if lower.contains("teacher") { return "teacher" }
        return "student"
    }

    private var avatarColor: Color {
        switch role {
        case "admin": return .purple
        case "teacher": return .green
        default: return .blue
        }
    }
}

// MARK: - Overview row

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

// MARK: - Sentinel card

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

// MARK: - Fullscreen view

struct ProctoringFullscreenView: View {
    let sentinelId: String
    let name: String
    let image: UIImage?
    let onDismiss: () -> Void

    @State private var controlsVisible = true
    @State private var controlsHideTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.width < geometry.size.height
            let safeArea = geometry.safeAreaInsets

            ZStack {
                Color.black.ignoresSafeArea()

                if let image {
                    ZoomableImage(image: image)
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
