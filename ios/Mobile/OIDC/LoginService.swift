//
//  LoginView.swift
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

    
    func discoverConfiguration(test : String) {

        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { config, error in
            
            guard let config = config else {
                       print("Failed to load config:", error?.localizedDescription ?? "Unknown error")
                       return
                   }
            
            let request = self.createAuthRequest(config)
            
            let viewController = UIApplication.shared.windows.first!.rootViewController!
            
            self.currentAuthFlow = OIDAuthState.authState(byPresenting: request, presenting: viewController) { authState, error in
                
                if let authState = authState {
                    print("Access token:", authState.lastTokenResponse?.accessToken ?? "")
                } else {
                    print("Auth error:", error?.localizedDescription ?? "")
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

}
