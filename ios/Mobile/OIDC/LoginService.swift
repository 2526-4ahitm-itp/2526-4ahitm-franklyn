//
//  LoginView.swift
//  Mobile
//
//  Created by Clemens Zangenfeind on 17.03.26.
//
import SwiftUI
import Combine
import AppAuth

class LoginService: ObservableObject {
    
    static let shared = LoginService()
    
    @Published var isLoggedIn: Bool = false
    @Published var userName: String?
    @Published var userEmail: String?
    
    private(set) var authState: OIDAuthState?
    
    private var currentAuthFlow: OIDExternalUserAgentSession?
    let issuer = URL(string: "https://auth.htl-leonding.ac.at/realms/franklyn")!

    func getValidAccessToken() async -> String? {
        guard let authState = authState else { return nil }
        
        return await withCheckedContinuation { continuation in
            authState.performAction { accessToken, idToken, error in
                if let error = error {
                    print("[LoginService] Token refresh error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: accessToken)
            }
        }
    }
    
    func discoverConfiguration(trigger: String) {

        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { config, error in
            
            guard let config = config else {
                       print("Failed to load config:", error?.localizedDescription ?? "Unknown error")
                       return
                   }
            
            let request = self.createAuthRequest(config)
            
            guard let viewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController else {
                print("Failed to get rootViewController")
                return
            }
            
            self.currentAuthFlow = OIDAuthState.authState(byPresenting: request, presenting: viewController) { authState, error in
                
                if let authState = authState {
                    let token = authState.lastTokenResponse?.accessToken ?? ""
                    DispatchQueue.main.async {
                        self.authState = authState
                        self.isLoggedIn = true
                        if let idToken = authState.lastTokenResponse?.idToken {
                            self.parseUserInfo(from: idToken)
                        }
                    }
                    print("Access token:", token)
                } else {
                    print("Auth error:", error?.localizedDescription ?? "")
                }
            }
        }
        
        
    }
    
    func createAuthRequest(_ config: OIDServiceConfiguration) -> OIDAuthorizationRequest {
        return OIDAuthorizationRequest(
            configuration: config,
            clientId: "mobile-ios",
            clientSecret: nil,
            scopes: ["openid", "profile"],
            redirectURL: URL(string: "franklynapp://login-callback")!,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
    }

    func resumeLogin(url: URL) -> Bool {
        if let flow = currentAuthFlow,
           flow.resumeExternalUserAgentFlow(with: url) {
            currentAuthFlow = nil
            return true
        }
        return false
    }
    
    func logout() {
        authState = nil
        isLoggedIn = false
        userName = nil
        userEmail = nil
    }
    
    private func parseUserInfo(from idToken: String) {
        let parts = idToken.split(separator: ".")
        guard parts.count >= 2,
              let payloadData = Data(base64Encoded: String(parts[1]).base64Padded) else { return }
        
        if let payload = try? JSONDecoder().decode(IdTokenPayload.self, from: payloadData) {
            userName = payload.name ?? payload.preferredUsername
            userEmail = payload.email
        }
    }

}

struct IdTokenPayload: Codable {
    let name: String?
    let preferredUsername: String?
    let email: String?
}

extension String {
    var base64Padded: String {
        let remainder = count % 4
        if remainder > 0 {
            return self + String(repeating: "=", count: 4 - remainder)
        }
        return self
    }
}
