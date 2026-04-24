import SwiftUI
import UIKit

struct ProctoringSentinelIdWrapper: Identifiable {
    let id: String
}

struct ProctoringDashboardView: View {
    @State private var store = WebsocketStore.shared
    @State private var selectedSentinel: ProctoringSentinelIdWrapper?
    @State private var seenStudents: [ProctoringStudentRecord] = []
    @State private var favouriteStudentIds = Set<String>()

    let examId: String
    let examTitle: String
    let examPin: Int?

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                overviewCard
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
                        selectedIds: $favouriteStudentIds
                    )
                } label: {
                    Label("Favourites", systemImage: "checklist")
                }
            }
        }
        .onAppear {
            loadPersistedStudents()
            store.connectWebsocket()
            if let examPin {
                store.setPinFilter(pin: examPin)
            }
        }
        .onDisappear {
            store.disconnect()
        }
        .fullScreenCover(item: $selectedSentinel) { sentinel in
            ProctoringFullscreenView(
                sentinelId: sentinel.id,
                name: store.sentinelName(for: sentinel.id) ?? sentinel.id,
                image: store.framesBySentinel[sentinel.id],
                onDismiss: { selectedSentinel = nil }
            )
        }
        .onChange(of: sentinelListSignature) {
            mergeCurrentConnectedStudentsIntoHistory()
        }
        .onChange(of: favouriteStudentIds) {
            ProctoringPreferencesStore.shared.setFavouriteStudentIds(favouriteStudentIds, for: examId)
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

                Text("Favourites \(favouriteStudentIds.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Overview")
                    .font(.headline)
                Spacer()
                Text("\(actualConnectedCount)/\(allTimeCount)")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.monospaced)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(actualConnectedCount == 1 ? "Student participating" : "Students participating")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            sentinelGrid
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var sentinelGrid: some View {
        let sentinelIds = store.framesBySentinel.keys.sorted()

        return VStack(alignment: .leading) {
            if sentinelIds.isEmpty {
                VStack(spacing: 8) {
                    Text("No sentinels connected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .padding(.bottom, 20)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(sentinelIds, id: \.self) { sentinelId in
                        Button {
                            selectedSentinel = ProctoringSentinelIdWrapper(id: sentinelId)
                        } label: {
                            ProctoringSentinelCard(
                                name: store.sentinelName(for: sentinelId) ?? sentinelId,
                                image: store.framesBySentinel[sentinelId]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var sentinelListSignature: String {
        store.sentinelList
            .map { "\($0.sentinelId)|\($0.name ?? "")" }
            .sorted()
            .joined(separator: "||")
    }

    private var actualConnectedCount: Int {
        Set(store.sentinelList.map(\.sentinelId)).count
    }

    private var allTimeCount: Int {
        seenStudents.count
    }

    private func loadPersistedStudents() {
        seenStudents = ProctoringPreferencesStore.shared.seenStudents(for: examId)
        favouriteStudentIds = ProctoringPreferencesStore.shared.favouriteStudentIds(for: examId)
        mergeCurrentConnectedStudentsIntoHistory()
    }

    private func mergeCurrentConnectedStudentsIntoHistory() {
        let currentStudents = store.sentinelList.map {
            ProctoringStudentRecord(
                sentinelId: $0.sentinelId,
                name: $0.name ?? $0.sentinelId
            )
        }

        guard !currentStudents.isEmpty else { return }

        ProctoringPreferencesStore.shared.mergeSeenStudents(currentStudents, for: examId)
        seenStudents = ProctoringPreferencesStore.shared.seenStudents(for: examId)
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
