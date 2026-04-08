//
//  WebsocketStore.swift
//  Mobile
//
//  Created by Clemens Zangenfeind on 08.04.26.
//

import Foundation
import Observation
import SwiftUI
import UIKit

// 1. Define the URL (use a public echo server for testing)


struct SentinelFrame: Codable {
    let sentinelId: String
    let data: String // Base64 string
}

// The generic wrapper for server messages
struct ServerMessage: Codable {
    let type: String
    let payload: Payload
    
    struct Payload: Codable {
        let frames: [SentinelFrame]?
        let sentinels: [SentinelInfo]?
    }
}

struct SentinelInfo: Codable {
    let sentinelId: String
    let pin: Int?
}

// The registration message we send to the server
struct ProctorRegister: Codable {
    let type: String = "proctor.register"
    let timestamp: Int = Int(Date().timeIntervalSince1970)
}

@Observable
class WebsocketStore {
    let url = URL(string: "ws://192.168.178.99:5050/api/ws/proctor")!
    var webSocketTask : URLSessionWebSocketTask?

    var framesBySentinel: [String: UIImage] = [:]
    var sentinelList: [SentinelInfo] = []
    var subscribedSentinels = Set<String>()
    private var currentPinFilter: Int?

    func connectWebsocket() {
        print("LOG: Attempting connection to \(url)...")
        
        guard let token = LoginService.shared.accessToken else {
            print("LOG: No access token available")
            return
        }
        
        let protocolHeader = "bearer-token-carrier,quarkus-http-upgrade#Authorization#Bearer \(token)"
        
        var request = URLRequest(url: url)
        request.setValue(protocolHeader, forHTTPHeaderField: "Sec-WebSocket-Protocol")

        print("LOG: Protocol Header: \(protocolHeader.prefix(80))...")

        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.webSocketTask?.sendPing { error in
                if let error = error {
                    print("LOG: Handshake failed or timed out: \(error)")
                } else {
                    print("LOG: Handshake SUCCESS. Starting listeners...")
                    self.receiveMessage()
                    self.sendRegisterMessage()
                }
            }
        }
    }
    
    private func checkConnection() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("LOG: Connection failed to stabilize: \(error.localizedDescription)")
            } else {
                print("LOG: SUCCESS! WebSocket is fully connected and upgraded.")
                self.sendRegisterMessage()
            }
        }
    }
    
    private func sendRegisterMessage() {
            let register = ProctorRegister()
            if let jsonData = try? JSONEncoder().encode(register),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                webSocketTask?.send(.string(jsonString)) { error in
                    if let error = error { print("Registration error: \(error)") }
                }
            }
        let subMessage: [String: Any] = [
            "type": "proctor.subscribe",
            "payload": ["sentinelId": "SENTINEL_ID_HERE"], // Put an actual ID from your laptop here
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        // Send this after registration!
        }
        
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                print("LOG: >>> RECEIVED DATA FROM SERVER")
                if case .string(let text) = message {
                    print("LOG: Payload: \(text.prefix(100))...") // Print first 100 chars
                    self?.handleIncomingText(text)
                }
                self?.receiveMessage() // Loop
                
            case .failure(let error):
                print("LOG: >>> RECEIVE ERROR: \(error.localizedDescription)")
                // Don't loop here, the connection is dead
            }
        }
    }
    private func handleIncomingText(_ text : String) {
        print("DEBUG: Received Message: \(text)")
            guard let data = text.data(using: .utf8) else { return }
            
            do {
                let serverMessage = try JSONDecoder().decode(ServerMessage.self, from: data)
                print("Success! Decoded message type: \(serverMessage.type)")
                
                if serverMessage.type == "server.frame", let frames = serverMessage.payload.frames {
                    Task { @MainActor in
                        print("LOG: Received \(frames.count) frames")
                        for frame in frames {
                            print("LOG: Frame from sentinel: \(frame.sentinelId)")
                            if let image = convertBase64ToImage(frame.data) {
                                self.framesBySentinel[frame.sentinelId] = image
                            }
                        }
                    }
                } else if serverMessage.type == "server.update-sentinels", let sentinels = serverMessage.payload.sentinels {
                    Task { @MainActor in
                        print("LOG: Received sentinel list update: \(sentinels.count) sentinels")
                        self.sentinelList = sentinels
                        for s in sentinels {
                            print("LOG: Sentinel - id: \(s.sentinelId), pin: \(s.pin ?? -1)")
                        }
                        self.updateSubscriptions()
                    }
                } else if serverMessage.type == "server.registration.ack" {
                    print("LOG: Registered as proctor successfully")
                }
            } catch {
                print("Decoding Error: \(error)")
                // This will tell you if a field name is missing or misspelled
            
        }
    }
    private func convertBase64ToImage(_ base64String: String) -> UIImage? {
            // Remove data header if present (e.g., "data:image/jpeg;base64,")
            let cleanString = base64String.components(separatedBy: ",").last ?? base64String
            
            guard let data = Data(base64Encoded: cleanString) else { return nil }
            return UIImage(data: data)
        }
        
        func disconnect() {
            webSocketTask?.cancel(with: .normalClosure, reason: nil)
            framesBySentinel.removeAll()
        }
    func subscribe(to sentinelId: String) {
        let message: [String: Any] = [
            "type": "proctor.subscribe",
            "payload": ["sentinelId": sentinelId],
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            print("LOG: Requesting frames for \(sentinelId)")
            webSocketTask?.send(.string(string)) { _ in }
            
            // Also set profile to LOW like your TS code did
            setProfile(for: sentinelId, profile: "LOW")
            subscribedSentinels.insert(sentinelId)
        }
    }

    func revokeSubscription(_ sentinelId: String) {
        let message: [String: Any] = [
            "type": "proctor.revoke-subscription",
            "payload": ["sentinelId": sentinelId],
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            print("LOG: Revoking subscription for \(sentinelId)")
            webSocketTask?.send(.string(string)) { _ in }
            subscribedSentinels.remove(sentinelId)
            framesBySentinel.removeValue(forKey: sentinelId)
        }
    }

    private func setProfile(for sentinelId: String, profile: String) {
        let message: [String: Any] = [
            "type": "proctor.set-profile",
            "payload": ["sentinelId": sentinelId, "profile": profile],
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(string)) { _ in }
        }
    }
    
    func setPinFilter(pin: Int) {
        let message: [String: Any] = [
            "type": "proctor.set-pin",
            "payload": ["pin": pin],
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            print("LOG: Setting PIN filter to \(pin)")
            webSocketTask?.send(.string(string)) { _ in }
            currentPinFilter = pin
            updateSubscriptions()
        }
    }
    
    func clearPinFilter() {
        let message: [String: Any] = [
            "type": "proctor.set-pin",
            "payload": ["pin": NSNull()],
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            print("LOG: Clearing PIN filter")
            webSocketTask?.send(.string(string)) { _ in }
            currentPinFilter = nil
            updateSubscriptions()
        }
    }
    
    private func updateSubscriptions() {
        for sentinel in sentinelList {
            let shouldSubscribe: Bool
            if let filter = currentPinFilter {
                shouldSubscribe = sentinel.pin == filter
            } else {
                shouldSubscribe = true
            }
            
            if shouldSubscribe && !subscribedSentinels.contains(sentinel.sentinelId) {
                subscribe(to: sentinel.sentinelId)
            } else if !shouldSubscribe && subscribedSentinels.contains(sentinel.sentinelId) {
                revokeSubscription(sentinel.sentinelId)
            }
        }
    }
}
