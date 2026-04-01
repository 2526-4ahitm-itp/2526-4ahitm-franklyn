import Apollo
import ApolloAPI
import Foundation

// MARK: - Authentication Interceptor

struct AuthenticationInterceptor: GraphQLInterceptor {
    
    func intercept<Request: GraphQLRequest>(
        request: Request,
        next: NextInterceptorFunction<Request>
    ) async throws -> InterceptorResultStream<Request> {
        var modifiedRequest = request
        
        // Get the current access token from LoginService
        if let token = LoginService.shared.accessToken {
            modifiedRequest.addHeader(name: "Authorization", value: "Bearer \(token)")
            print("[AuthInterceptor] Added auth header with token: \(token.prefix(20))...")
        } else {
            print("[AuthInterceptor] No valid token available - user may not be logged in")
        }
        
        return await next(modifiedRequest)
    }
}

// MARK: - Custom Interceptor Provider

struct AuthenticatedInterceptorProvider: InterceptorProvider {
    
    func graphQLInterceptors<Operation: GraphQLOperation>(for operation: Operation) -> [any GraphQLInterceptor] {
        return [
            AuthenticationInterceptor(),
            MaxRetryInterceptor(),
            AutomaticPersistedQueryInterceptor()
        ]
    }
    
    func cacheInterceptor<Operation: GraphQLOperation>(for operation: Operation) -> any CacheInterceptor {
        DefaultCacheInterceptor()
    }
    
    func httpInterceptors<Operation: GraphQLOperation>(for operation: Operation) -> [any HTTPInterceptor] {
        return [
            ResponseCodeInterceptor()
        ]
    }
    
    func responseParser<Operation: GraphQLOperation>(for operation: Operation) -> any ResponseParsingInterceptor {
        JSONResponseParsingInterceptor()
    }
}

// MARK: - Authenticated Apollo Client

class Network {
    static let shared = Network()
    
    private(set) lazy var apollo: ApolloClient = {
        let url = URL(string: "http://localhost:5050/api/graphql")!
        let store = ApolloStore(cache: InMemoryNormalizedCache())
        let provider = AuthenticatedInterceptorProvider()
        let transport = RequestChainNetworkTransport(
            urlSession: URLSession(configuration: .default),
            interceptorProvider: provider,
            store: store,
            endpointURL: url
        )
        return ApolloClient(
            networkTransport: transport,
            store: store
        )
    }()
}

let apolloClient = Network.shared.apollo

// MARK: - Test Model

struct FrTest: Identifiable {
    let id: String
    var title: String
    var startTime: Date?
    var endTime: Date?
    var teacherId: String?

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
    init?(from gql: FranklynAPI.GetTestsQuery.Data.Test) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title ?? "Untitled"
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.teacherId = gql.teacherId
    }

    init?(from gql: FranklynAPI.GetTestByIdQuery.Data.TestId) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title ?? "Untitled"
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.teacherId = gql.teacherId
    }

    init?(from gql: FranklynAPI.CreateTestMutation.Data.CreateTest) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title ?? "Untitled"
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.teacherId = gql.teacherId
    }

    init?(from gql: FranklynAPI.UpdateTestMutation.Data.UpdateTest) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title ?? "Untitled"
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.teacherId = gql.teacherId
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
            let result = try await apolloClient.fetch(query: FranklynAPI.GetTestsQuery())
            let gqlTests = result.data?.tests ?? []
            tests = gqlTests.compactMap { $0 }.compactMap { FrTest(from: $0) }
            print("[TestStore] Fetched \(tests.count) tests: \(tests.map { "\($0.id): \($0.title)" })")
        } catch {
            print("[TestStore] Fetch error: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Create test

    func createTest(title: String, startTime: Date?) async {
        errorMessage = nil
        let startVal: GraphQLNullable<String> = startTime.map { .some(formatISO8601($0)) } ?? .none
        let input = FranklynAPI.TestInput(
            endTime: .none,
            startTime: startVal,
            title: .some(title)
        )
        do {
            print("[TestStore] Creating test '\(title)'...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.CreateTestMutation(test: .some(input)))
            if let created = result.data?.createTest {
                let createdId = created.id ?? "nil"
                let createdTitle = created.title ?? "nil"
                print("[TestStore] Created test id=\(createdId) title=\(createdTitle)")
                if let mapped = FrTest(from: created) {
                    tests.append(mapped)
                }
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
    func deleteTest(id: String) async -> Bool {
        errorMessage = nil
        do {
            print("[TestStore] Deleting test id=\(id)...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.DeleteTestMutation(id: .some(id)))
            if let errors = result.errors, !errors.isEmpty {
                print("[TestStore] Delete response errors: \(errors.map { $0.message })")
            }
            if let deleted = result.data?.deleteTest {
                tests.removeAll { $0.id == id }
                print("[TestStore] Deleted test id=\(id), response=\(deleted), remaining: \(tests.count)")
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

    func startTest(id: String) async {
        guard let test = tests.first(where: { $0.id == id }) else { return }
        errorMessage = nil
        let endVal: GraphQLNullable<String> = test.endTime.map { .some(formatISO8601($0)) } ?? .none
        let input = FranklynAPI.TestInput(
            endTime: endVal,
            startTime: .some(formatISO8601(Date())),
            title: .some(test.title)
        )
        do {
            print("[TestStore] Starting test id=\(id) with input: title=\(test.title), startTime=\(formatISO8601(Date()))")
            let result = try await apolloClient.perform(mutation: FranklynAPI.UpdateTestMutation(id: .some(id), test: .some(input)))
            if let errors = result.errors, !errors.isEmpty {
                print("[TestStore] Start response errors: \(errors.map { $0.message })")
            }
            if let updated = result.data?.updateTest {
                if let mapped = FrTest(from: updated), let idx = tests.firstIndex(where: { $0.id == id }) {
                    tests[idx] = mapped
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

    func endTest(id: String) async {
        guard let test = tests.first(where: { $0.id == id }) else { return }
        errorMessage = nil
        let startVal: GraphQLNullable<String> = test.startTime.map { .some(formatISO8601($0)) } ?? .none
        let input = FranklynAPI.TestInput(
            endTime: .some(formatISO8601(Date())),
            startTime: startVal,
            title: .some(test.title)
        )
        do {
            print("[TestStore] Ending test id=\(id) with endTime=\(formatISO8601(Date()))...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.UpdateTestMutation(id: .some(id), test: .some(input)))
            if let errors = result.errors, !errors.isEmpty {
                print("[TestStore] End response errors: \(errors.map { $0.message })")
            }
            if let updated = result.data?.updateTest {
                if let mapped = FrTest(from: updated), let idx = tests.firstIndex(where: { $0.id == id }) {
                    tests[idx] = mapped
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
