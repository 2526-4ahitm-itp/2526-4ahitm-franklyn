import Apollo
import Foundation

let apolloClient = ApolloClient(url: URL(string: "http://localhost:5050/api/graphql")!)

// MARK: - Test Model

struct FrTest: Identifiable {
    let id: Int
    var title: String
    var startTime: Date?
    var endTime: Date?
    var teacherId: Int?
    var testAccountPrefix: String?

    enum State {
        case active
        case future
        case past
    }

    var state: State {
        let now = Date()
        if let end = endTime, end <= now {
            return .past
        }
        if let start = startTime, start <= now {
            return .active
        }
        return .future
    }
}

// MARK: - Date Parsing

private let iso8601Formatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

private let iso8601FormatterNoFrac: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
}()

/// Formatter for sending dates to the server.
/// Server uses LocalDateTime (no timezone), but all times are UTC.
/// Format: "yyyy-MM-dd'T'HH:mm:ss"
private let serverDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    f.timeZone = TimeZone(identifier: "UTC")
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

func parseISO8601(_ string: String?) -> Date? {
    guard let string else { return nil }
    return iso8601Formatter.date(from: string)
        ?? iso8601FormatterNoFrac.date(from: string)
        ?? serverDateFormatter.date(from: string)
}

func formatISO8601(_ date: Date) -> String {
    serverDateFormatter.string(from: date)
}

// MARK: - Mapping helpers

extension FrTest {
    init(from gql: FranklynAPI.GetTestsQuery.Data.Test) {
        self.id = gql.id
        self.title = gql.title ?? "Untitled"
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.teacherId = gql.teacherId
        self.testAccountPrefix = gql.testAccountPrefix
    }

    init(from gql: FranklynAPI.GetTestByIdQuery.Data.TestId) {
        self.id = gql.id
        self.title = gql.title ?? "Untitled"
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.teacherId = gql.teacherId
        self.testAccountPrefix = gql.testAccountPrefix
    }

    init(from gql: FranklynAPI.CreateTestMutation.Data.CreateTest) {
        self.id = gql.id
        self.title = gql.title ?? "Untitled"
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.teacherId = gql.teacherId
        self.testAccountPrefix = gql.testAccountPrefix
    }

    init(from gql: FranklynAPI.UpdateTestMutation.Data.UpdateTest) {
        self.id = gql.id
        self.title = gql.title ?? "Untitled"
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.teacherId = gql.teacherId
        self.testAccountPrefix = gql.testAccountPrefix
    }
}

// MARK: - Observable Store

@Observable
@MainActor
final class TestStore {
    var tests: [FrTest] = []
    var isLoading = false
    var errorMessage: String?

    // Grouped & sorted computed properties
    var activeTests: [FrTest] {
        tests
            .filter { $0.state == .active }
            .sorted { ($0.startTime ?? .distantPast) > ($1.startTime ?? .distantPast) }
    }

    var futureTests: [FrTest] {
        tests
            .filter { $0.state == .future }
            .sorted { ($0.startTime ?? .distantFuture) < ($1.startTime ?? .distantFuture) }
    }

    var pastTests: [FrTest] {
        tests
            .filter { $0.state == .past }
            .sorted { ($0.endTime ?? .distantPast) > ($1.endTime ?? .distantPast) }
    }

    // MARK: - Fetch all tests

    func fetchTests() async {
        isLoading = true
        errorMessage = nil
        do {
            print("[TestStore] Fetching tests from server...")
            try await apolloClient.store.clearCache()
            let result = try await apolloClient.fetch(query: FranklynAPI.GetTestsQuery())
            let gqlTests = result.data?.tests ?? []
            tests = gqlTests.compactMap { $0 }.map { FrTest(from: $0) }
            print("[TestStore] Fetched \(tests.count) tests: \(tests.map { "\($0.id): \($0.title)" })")
        } catch {
            print("[TestStore] Fetch error: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Create test

    private var randomId: Int {
        Int.random(in: 0 ... 100_000)
    }

    func createTest(title: String, startTime: Date?, testAccountPrefix: String?) async {
        errorMessage = nil
        let startVal: GraphQLNullable<String> = startTime.map { .some(formatISO8601($0)) } ?? .none
        let prefixVal: GraphQLNullable<String> = testAccountPrefix.map { .some($0) } ?? .none
        let newId = randomId
        let input = FranklynAPI.InsertTestRowInput(
            endTime: .none,
            id: newId,
            startTime: startVal,
            teacherId: .none,
            testAccountPrefix: prefixVal,
            title: .some(title)
        )
        do {
            print("[TestStore] Creating test '\(title)' with id=\(newId)...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.CreateTestMutation(test: .some(input)))
            if let created = result.data?.createTest {
                print("[TestStore] Created test id=\(created.id) title=\(created.title ?? "nil")")
                tests.append(FrTest(from: created))
            } else {
                print("[TestStore] Create returned nil data")
            }
        } catch {
            print("[TestStore] Create error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete test

    @discardableResult
    func deleteTest(id: Int) async -> Bool {
        errorMessage = nil
        do {
            print("[TestStore] Deleting test id=\(id)...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.DeleteTestMutation(id: id))
            print("[TestStore] Delete response errors: \(result.errors?.map { $0.message } ?? [])")
            if let deleted = result.data?.deleteTest {
                tests.removeAll { $0.id == id }
                print("[TestStore] Deleted test id=\(deleted.id), remaining: \(tests.count)")
                return true
            } else {
                print("[TestStore] Delete returned nil data")
                return false
            }
        } catch {
            print("[TestStore] Delete error: \(error)")
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Start test (set startTime = now)

    func startTest(id: Int) async {
        guard let test = tests.first(where: { $0.id == id }) else { return }
        errorMessage = nil
        let teacherVal: GraphQLNullable<Int> = test.teacherId.map { .some($0) } ?? .none
        let prefixVal: GraphQLNullable<String> = test.testAccountPrefix.map { .some($0) } ?? .none
        let input = FranklynAPI.UpdateTestRowInput(
            endTime: .none,
            id: id,
            startTime: .some(formatISO8601(Date())),
            teacherId: teacherVal,
            testAccountPrefix: prefixVal,
            title: .some(test.title)
        )
        do {
            print("[TestStore] Starting test id=\(id) with input: title=\(test.title), startTime=\(formatISO8601(Date()))")
            let result = try await apolloClient.perform(mutation: FranklynAPI.UpdateTestMutation(id: id, test: .some(input)))
            print("[TestStore] Start response errors: \(result.errors?.map { $0.message } ?? [])")
            if let updated = result.data?.updateTest {
                if let idx = tests.firstIndex(where: { $0.id == id }) {
                    tests[idx] = FrTest(from: updated)
                }
                print("[TestStore] Started test id=\(id), startTime=\(updated.startTime ?? "nil")")
            } else {
                print("[TestStore] Start returned nil data")
            }
        } catch {
            print("[TestStore] Start error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - End test (set endTime = now)

    func endTest(id: Int) async {
        guard let test = tests.first(where: { $0.id == id }) else { return }
        errorMessage = nil
        let startVal: GraphQLNullable<String> = test.startTime.map { .some(formatISO8601($0)) } ?? .none
        let teacherVal: GraphQLNullable<Int> = test.teacherId.map { .some($0) } ?? .none
        let prefixVal: GraphQLNullable<String> = test.testAccountPrefix.map { .some($0) } ?? .none
        let input = FranklynAPI.UpdateTestRowInput(
            endTime: .some(formatISO8601(Date())),
            id: id,
            startTime: startVal,
            teacherId: teacherVal,
            testAccountPrefix: prefixVal,
            title: .some(test.title)
        )
        do {
            print("[TestStore] Ending test id=\(id) with endTime=\(formatISO8601(Date()))...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.UpdateTestMutation(id: id, test: .some(input)))
            print("[TestStore] End response errors: \(result.errors?.map { $0.message } ?? [])")
            if let updated = result.data?.updateTest {
                if let idx = tests.firstIndex(where: { $0.id == id }) {
                    tests[idx] = FrTest(from: updated)
                }
                print("[TestStore] Ended test id=\(id), endTime=\(updated.endTime ?? "nil")")
            } else {
                print("[TestStore] End returned nil data")
            }
        } catch {
            print("[TestStore] End error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}
