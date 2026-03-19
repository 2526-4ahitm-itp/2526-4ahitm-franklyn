//
//  TokenStorage.swift
//  Mobile
//
//  Created by Clemens Zangenfeind on 17.03.26.
//

import Foundation
import AppAuth

/// Singleton for storing and retrieving the OIDC auth state (including access token).
class TokenStorage {
    static let shared = TokenStorage()
    
    private let keychainKey = "com.franklyn.authState"
    
    private init() {}
    
    /// The current OIDAuthState, if available.
    private(set) var authState: OIDAuthState? {
        didSet {
            saveToKeychain()
        }
    }
    
    /// The current access token, if available and not expired.
    var accessToken: String? {
        // If token is expired, try to refresh first
        if let authState = authState,
           let tokenResponse = authState.lastTokenResponse,
           let expirationDate = tokenResponse.accessTokenExpirationDate,
           expirationDate > Date() {
            return tokenResponse.accessToken
        }
        return authState?.lastTokenResponse?.accessToken
    }
    
    /// Whether user is currently authenticated with a valid token.
    var isAuthenticated: Bool {
        return accessToken != nil
    }
    
    /// Store a new auth state after successful login.
    func setAuthState(_ state: OIDAuthState?) {
        self.authState = state
    }
    
    /// Clear the stored auth state (logout).
    func clearAuthState() {
        self.authState = nil
        removeFromKeychain()
    }
    
    /// Refresh the access token if needed.
    func refreshTokenIfNeeded() async throws -> String? {
        guard let authState = authState else { return nil }
        
        return try await withCheckedThrowingContinuation { continuation in
            authState.performAction { accessToken, idToken, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: accessToken)
                }
            }
        }
    }
    
    // MARK: - Keychain Persistence
    
    /// Load auth state from keychain on app launch.
    func loadFromKeychain() {
        guard let data = KeychainHelper.load(key: keychainKey) else { return }
        
        do {
            if let authState = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: OIDAuthState.self,
                from: data
            ) {
                self.authState = authState
            }
        } catch {
            print("[TokenStorage] Failed to load auth state: \(error)")
        }
    }
    
    private func saveToKeychain() {
        guard let authState = authState else {
            removeFromKeychain()
            return
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: authState,
                requiringSecureCoding: true
            )
            KeychainHelper.save(key: keychainKey, data: data)
        } catch {
            print("[TokenStorage] Failed to save auth state: \(error)")
        }
    }
    
    private func removeFromKeychain() {
        KeychainHelper.delete(key: keychainKey)
    }
}

// MARK: - Keychain Helper

private enum KeychainHelper {
    static func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
