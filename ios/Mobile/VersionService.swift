import Foundation

@Observable
@MainActor
final class VersionService {
    static let shared = VersionService()
    
    var version: String = "1.0.0"
    var build: String = "1"
    var isLoading = false
    
    private let versionURL = URL(string: "https://raw.githubusercontent.com/2526-4ahitm-itp/2526-4ahitm-franklyn/main/VERSION")!
    
    func fetchVersion() async {
        isLoading = true
        do {
            let (data, _) = try await URLSession.shared.data(from: versionURL)
            if let versionString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                let parts = versionString.split(separator: "+")
                version = String(parts.first ?? "1.0.0")
                if parts.count > 1 {
                    build = String(parts[1])
                } else {
                    build = "1"
                }
            }
        } catch {
            print("Failed to fetch version: \(error)")
        }
        isLoading = false
    }
}
