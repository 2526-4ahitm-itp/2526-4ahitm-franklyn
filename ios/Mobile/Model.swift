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

// MARK: - Exam Model

struct FrExam: Identifiable {
    let id: String
    var title: String
    var startTime: Date?
    var endTime: Date?
    var startedAt: Date?
    var endedAt: Date?
    var teacherId: String?
    var pin: Int?

    enum State {
        case live
        case scheduled
        case completed
    }

    var state: State {
        if endedAt != nil {
            return .completed
        }
        if startedAt != nil {
            return .live
        }
        return .scheduled
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

private let serverDateFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    f.timeZone = TimeZone(identifier: "UTC")
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

extension FrExam {
    init?(from gql: FranklynAPI.GetExamsQuery.Data.Exam) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.startedAt = parseISO8601(gql.startedAt)
        self.endedAt = parseISO8601(gql.endedAt)
        self.teacherId = gql.teacherId
        self.pin = gql.pin
    }

    init?(from gql: FranklynAPI.GetExamByIdQuery.Data.ExamById) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.startedAt = parseISO8601(gql.startedAt)
        self.endedAt = parseISO8601(gql.endedAt)
        self.teacherId = gql.teacherId
        self.pin = gql.pin
    }

    init?(from gql: FranklynAPI.CreateExamMutation.Data.CreateExam) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.startedAt = parseISO8601(gql.startedAt)
        self.endedAt = parseISO8601(gql.endedAt)
        self.teacherId = gql.teacherId
        self.pin = gql.pin
    }

    init?(from gql: FranklynAPI.StartExamMutation.Data.StartExam) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.startedAt = parseISO8601(gql.startedAt)
        self.endedAt = parseISO8601(gql.endedAt)
        self.teacherId = gql.teacherId
        self.pin = gql.pin
    }

    init?(from gql: FranklynAPI.EndExamMutation.Data.EndExam) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.startedAt = parseISO8601(gql.startedAt)
        self.endedAt = parseISO8601(gql.endedAt)
        self.teacherId = gql.teacherId
        self.pin = gql.pin
    }

    init?(from gql: FranklynAPI.UpdateExamScheduleMutation.Data.UpdateExamSchedule) {
        guard let id = gql.id else { return nil }
        self.id = id
        self.title = gql.title
        self.startTime = parseISO8601(gql.startTime)
        self.endTime = parseISO8601(gql.endTime)
        self.startedAt = parseISO8601(gql.startedAt)
        self.endedAt = parseISO8601(gql.endedAt)
        self.teacherId = gql.teacherId
        self.pin = gql.pin
    }
}

// MARK: - Observable Store

@Observable
@MainActor
final class ExamStore {
    var exams: [FrExam] = []
    var isLoading = false
    var errorMessage: String?

    // Grouped & sorted computed properties
    var liveExams: [FrExam] {
        exams
            .filter { $0.state == .live }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
    }

    var scheduledExams: [FrExam] {
        exams
            .filter { $0.state == .scheduled }
            .sorted { ($0.startTime ?? .distantFuture) < ($1.startTime ?? .distantFuture) }
    }

    var completedExams: [FrExam] {
        exams
            .filter { $0.state == .completed }
            .sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }
    }

    // MARK: - Fetch all exams

    func fetchExams() async {
        isLoading = true
        errorMessage = nil
        do {
            print("[ExamStore] Clearing cache and fetching exams from server...")
            try await apolloClient.store.clearCache()
            let result = try await apolloClient.fetch(query: FranklynAPI.GetExamsQuery())
            let gqlExams = result.data?.exams ?? []
            exams = gqlExams.compactMap { $0 }.compactMap { FrExam(from: $0) }
            print("[ExamStore] Fetched \(exams.count) exams: \(exams.map { "\($0.id): \($0.title)" })")
        } catch {
            print("[ExamStore] Fetch error: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Create exam

    func createExam(title: String, startTime: Date?) async {
        errorMessage = nil
        let scheduleStart = startTime ?? Date()
        let scheduleEnd = Calendar.current.date(byAdding: .hour, value: 1, to: scheduleStart) ?? scheduleStart
        let input = FranklynAPI.InsertExamInput(
            endTime: formatISO8601(scheduleEnd),
            startTime: formatISO8601(scheduleStart),
            title: title
        )
        do {
            print("[ExamStore] Creating exam '\(title)' with schedule=\(formatISO8601(scheduleStart)) - \(formatISO8601(scheduleEnd))...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.CreateExamMutation(exam: input))
            if let created = result.data?.createExam {
                let createdId = created.id ?? "nil"
                let createdTitle = created.title
                print("[ExamStore] Created exam id=\(createdId) title=\(createdTitle)")
                if let mapped = FrExam(from: created) {
                    exams.append(mapped)
                }
            } else {
                print("[ExamStore] Create returned nil data")
            }
        } catch {
            print("[ExamStore] Create error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete exam

    @discardableResult
    func deleteExam(id: String) async -> Bool {
        errorMessage = nil
        do {
            print("[ExamStore] Deleting exam id=\(id)...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.DeleteExamMutation(id: id))
            if let errors = result.errors, !errors.isEmpty {
                print("[ExamStore] Delete response errors: \(errors.map { $0.message })")
                errorMessage = errors.first?.message
                return false
            }
            exams.removeAll { $0.id == id }
            print("[ExamStore] Deleted exam id=\(id), remaining: \(exams.count)")
            return true
        } catch {
            print("[ExamStore] Delete error: \(error)")
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Start exam

    func startExam(id: String) async {
        errorMessage = nil
        do {
            print("[ExamStore] Starting exam id=\(id)...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.StartExamMutation(id: id))
            if let errors = result.errors, !errors.isEmpty {
                print("[ExamStore] Start response errors: \(errors.map { $0.message })")
            }
            if let updated = result.data?.startExam {
                if let mapped = FrExam(from: updated), let idx = exams.firstIndex(where: { $0.id == id }) {
                    exams[idx] = mapped
                }
                print("[ExamStore] Started exam id=\(id), startTime=\(updated.startTime)")
            } else {
                print("[ExamStore] Start returned nil data")
            }
        } catch {
            print("[ExamStore] Start error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - End exam

    func endExam(id: String) async {
        errorMessage = nil
        do {
            print("[ExamStore] Ending exam id=\(id)...")
            let result = try await apolloClient.perform(mutation: FranklynAPI.EndExamMutation(id: id))
            if let errors = result.errors, !errors.isEmpty {
                print("[ExamStore] End response errors: \(errors.map { $0.message })")
            }
            if let updated = result.data?.endExam {
                if let mapped = FrExam(from: updated), let idx = exams.firstIndex(where: { $0.id == id }) {
                    exams[idx] = mapped
                }
                print("[ExamStore] Ended exam id=\(id), endTime=\(updated.endTime)")
            } else {
                print("[ExamStore] End returned nil data")
            }
        } catch {
            print("[ExamStore] End error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}
