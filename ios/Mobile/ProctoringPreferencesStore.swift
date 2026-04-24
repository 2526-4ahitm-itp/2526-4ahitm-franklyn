import Foundation

struct ProctoringStudentRecord: Codable, Identifiable, Hashable {
    let sentinelId: String
    var name: String

    var id: String { sentinelId }
}

@MainActor
final class ProctoringPreferencesStore {
    static let shared = ProctoringPreferencesStore()

    private let defaults = UserDefaults.standard
    private let seenStudentsKey = "proctoring.seenStudentsByExam"
    private let favouriteStudentsKey = "proctoring.favouriteStudentsByExam"

    private init() {}

    func seenStudents(for examId: String) -> [ProctoringStudentRecord] {
        loadSeenStudentsByExam()[examId] ?? []
    }

    func mergeSeenStudents(_ students: [ProctoringStudentRecord], for examId: String) {
        guard !examId.isEmpty else { return }

        var all = loadSeenStudentsByExam()
        var merged = Dictionary(uniqueKeysWithValues: (all[examId] ?? []).map { ($0.sentinelId, $0) })

        for student in students {
            merged[student.sentinelId] = student
        }

        all[examId] = merged.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        saveSeenStudentsByExam(all)
    }

    func favouriteStudentIds(for examId: String) -> Set<String> {
        let all = loadFavouriteStudentsByExam()
        return Set(all[examId] ?? [])
    }

    func setFavouriteStudentIds(_ ids: Set<String>, for examId: String) {
        guard !examId.isEmpty else { return }

        var all = loadFavouriteStudentsByExam()
        all[examId] = Array(ids).sorted()
        saveFavouriteStudentsByExam(all)
    }

    private func loadSeenStudentsByExam() -> [String: [ProctoringStudentRecord]] {
        guard let data = defaults.data(forKey: seenStudentsKey) else { return [:] }
        return (try? JSONDecoder().decode([String: [ProctoringStudentRecord]].self, from: data)) ?? [:]
    }

    private func saveSeenStudentsByExam(_ map: [String: [ProctoringStudentRecord]]) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        defaults.set(data, forKey: seenStudentsKey)
    }

    private func loadFavouriteStudentsByExam() -> [String: [String]] {
        guard let data = defaults.data(forKey: favouriteStudentsKey) else { return [:] }
        return (try? JSONDecoder().decode([String: [String]].self, from: data)) ?? [:]
    }

    private func saveFavouriteStudentsByExam(_ map: [String: [String]]) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        defaults.set(data, forKey: favouriteStudentsKey)
    }
}
