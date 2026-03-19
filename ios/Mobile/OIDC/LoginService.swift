//
//  LoginService.swift
//  Mobile
//
//  Created by Clemens Zangenfeind on 17.03.26.
//
import SwiftUI
import AppAuth

class LoginService {
    
    static let shared = LoginService()
    
    private var currentAuthFlow: OIDExternalUserAgentSession?
    let issuer = URL(string: "https://auth.htl-leonding.ac.at/realms/franklyn")!
    
    /// Callback invoked when login completes (success or failure).
    var onLoginComplete: ((Bool, Error?) -> Void)?
    
    func discoverConfiguration(test: String) {

        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { config, error in
            
            guard let config = config else {
                print("[LoginService] Failed to load config:", error?.localizedDescription ?? "Unknown error")
                self.onLoginComplete?(false, error)
                return
            }
            
            let request = self.createAuthRequest(config)
            
            guard let viewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController else {
                print("[LoginService] Failed to get rootViewController")
                self.onLoginComplete?(false, nil)
                return
            }
            
            self.currentAuthFlow = OIDAuthState.authState(byPresenting: request, presenting: viewController) { authState, error in
                
                if let authState = authState {
                    // Store the auth state for later use
                    TokenStorage.shared.setAuthState(authState)
                    print("[LoginService] Login successful, access token stored")
                    print("[LoginService] Access token:", authState.lastTokenResponse?.accessToken?.prefix(50) ?? "nil", "...")
                    self.onLoginComplete?(true, nil)
                } else {
                    print("[LoginService] Auth error:", error?.localizedDescription ?? "")
                    self.onLoginComplete?(false, error)
                }
            }
        }
    }
    
    func createAuthRequest(_ config: OIDServiceConfiguration) -> OIDAuthorizationRequest {
        return OIDAuthorizationRequest(
            configuration: config,
            clientId: "ios-client",
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
    
    /// Logout: clear stored tokens.
    func logout() {
        TokenStorage.shared.clearAuthState()
        print("[LoginService] Logged out, tokens cleared")
    }
}
