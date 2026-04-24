import Foundation

struct ProctoringStudentRecord: Codable, Identifiable, Hashable {
    let nameKey: String
    var name: String

    var id: String { nameKey }

    init(name: String) {
        self.name = name
        self.nameKey = ProctoringPreferencesStore.normalizeName(name)
    }
}

@MainActor
final class ProctoringPreferencesStore {
    static let shared = ProctoringPreferencesStore()

    private let defaults = UserDefaults.standard
    private let seenStudentsKey = "proctoring.seenStudentsByExam"
    private let favouriteStudentsKey = "proctoring.favouriteStudentsByExam"

    private init() {}

    nonisolated static func normalizeName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private nonisolated static func isLikelyUUIDKey(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return UUID(uuidString: trimmed) != nil
    }

    func seenStudents(for examId: String) -> [ProctoringStudentRecord] {
        loadSeenStudentsByExam()[examId] ?? []
    }

    func mergeSeenStudents(_ students: [ProctoringStudentRecord], for examId: String) {
        guard !examId.isEmpty else { return }

        var all = loadSeenStudentsByExam()
        var merged = deduplicatedByNameKey(all[examId] ?? [])

        for student in students {
            guard !student.nameKey.isEmpty else { continue }
            guard !Self.isLikelyUUIDKey(student.nameKey) else { continue }

            if var existing = merged[student.nameKey] {
                existing.name = student.name
                merged[student.nameKey] = existing
            } else {
                merged[student.nameKey] = student
            }
        }

        all[examId] = merged.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        saveSeenStudentsByExam(all)
    }

    func favouriteStudentNameKeys(for examId: String) -> Set<String> {
        let all = loadFavouriteStudentsByExam()
        let rawKeys = Set(all[examId] ?? []).map(Self.normalizeName)
        let allowedKeys = Set(seenStudents(for: examId).map(\.nameKey))
        return Set(rawKeys.filter { !$0.isEmpty && !Self.isLikelyUUIDKey($0) && allowedKeys.contains($0) })
    }

    func setFavouriteStudentNameKeys(_ keys: Set<String>, for examId: String) {
        guard !examId.isEmpty else { return }

        var all = loadFavouriteStudentsByExam()
        all[examId] = Array(keys.map(Self.normalizeName).filter { !$0.isEmpty && !Self.isLikelyUUIDKey($0) }).sorted()
        saveFavouriteStudentsByExam(all)
    }

    private func loadSeenStudentsByExam() -> [String: [ProctoringStudentRecord]] {
        guard let data = defaults.data(forKey: seenStudentsKey) else { return [:] }
        if let map = try? JSONDecoder().decode([String: [ProctoringStudentRecord]].self, from: data) {
            return map.mapValues { records in
                Array(deduplicatedByNameKey(records).values)
            }
        }

        if let legacyMap = try? JSONDecoder().decode([String: [LegacyStudentRecord]].self, from: data) {
            return legacyMap.mapValues { records in
                records.map { legacy in
                    ProctoringStudentRecord(name: legacy.name)
                }
            }
        }

        return [:]
    }

    private func deduplicatedByNameKey(_ records: [ProctoringStudentRecord]) -> [String: ProctoringStudentRecord] {
        var merged: [String: ProctoringStudentRecord] = [:]

        for record in records {
            guard !record.nameKey.isEmpty else { continue }
            guard !Self.isLikelyUUIDKey(record.nameKey) else { continue }

            if var existing = merged[record.nameKey] {
                existing.name = record.name
                merged[record.nameKey] = existing
            } else {
                merged[record.nameKey] = record
            }
        }

        return merged
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

    private struct LegacyStudentRecord: Codable {
        let sentinelId: String
        let name: String
    }
}
