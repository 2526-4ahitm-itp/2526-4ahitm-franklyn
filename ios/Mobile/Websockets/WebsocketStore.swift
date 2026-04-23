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

struct WebsocketEnvelope<Payload: Codable>: Codable {
    let type: String
    let payload: Payload
    let timestamp: Int

    init(type: String, payload: Payload, timestamp: Int = Int(Date().timeIntervalSince1970)) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
    }
}

struct ProctorRegisterPayload: Codable {
    let auth: String
}

struct ProctorSubscribePayload: Codable {
    let sentinelId: String
}

struct ProctorSetProfilePayload: Codable {
    let sentinelId: String
    let profile: String
}

struct ProctorSetPinPayload: Codable {
    let pin: Int
}

// The generic wrapper for server messages
struct ServerMessage: Codable {
    let type: String
    let payload: Payload
    
    struct Payload: Codable {
        let frames: [SentinelFrame]?
        let sentinels: [SentinelInfo]?
        let sentinelId: String?
        let reason: String?
        let proctorId: String?
    }
}

struct SentinelInfo: Codable {
    let sentinelId: String
    let name: String?
    let pin: Int?
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

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()

        receiveMessage()
        sendRegisterMessage(authToken: token)
    }

    private func sendRegisterMessage(authToken: String) {
        let register = WebsocketEnvelope(
            type: "proctor.register",
            payload: ProctorRegisterPayload(auth: authToken)
        )
        send(message: register, logPrefix: "Registration")
    }

    private func send<Message: Encodable>(message: Message, logPrefix: String? = nil) {
        guard let data = try? JSONEncoder().encode(message),
              let text = String(data: data, encoding: .utf8)
        else {
            print("LOG: Failed to encode websocket message")
            return
        }

        webSocketTask?.send(.string(text)) { error in
            if let error {
                if let logPrefix {
                    print("\(logPrefix) error: \(error.localizedDescription)")
                } else {
                    print("Send error: \(error.localizedDescription)")
                }
            }
        }
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
                            print("LOG: Sentinel - id: \(s.sentinelId), name: \(s.name ?? "unknown"), pin: \(s.pin ?? -1)")
                        }
                        self.updateSubscriptions()
                    }
                } else if serverMessage.type == "server.registration.ack" {
                    print("LOG: Registered as proctor successfully (id: \(serverMessage.payload.proctorId ?? "unknown"))")
                } else if serverMessage.type == "server.registration.reject" {
                    print("LOG: Registration rejected: \(serverMessage.payload.reason ?? "unknown reason")")
                    Task { @MainActor in
                        self.disconnect()
                    }
                } else if serverMessage.type == "server.sentinel-disconnected" {
                    if let sentinelId = serverMessage.payload.sentinelId {
                        Task { @MainActor in
                            print("LOG: Sentinel disconnected: \(sentinelId)")
                            self.framesBySentinel.removeValue(forKey: sentinelId)
                            self.subscribedSentinels.remove(sentinelId)
                            self.sentinelList.removeAll { $0.sentinelId == sentinelId }
                        }
                    }
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
        let message = WebsocketEnvelope(
            type: "proctor.subscribe",
            payload: ProctorSubscribePayload(sentinelId: sentinelId)
        )

        print("LOG: Requesting frames for \(sentinelId)")
        send(message: message)

        // Also set profile to LOW like the Proctor app.
        setProfile(for: sentinelId, profile: "LOW")
        subscribedSentinels.insert(sentinelId)
    }

    func revokeSubscription(_ sentinelId: String) {
        let message = WebsocketEnvelope(
            type: "proctor.revoke-subscription",
            payload: ProctorSubscribePayload(sentinelId: sentinelId)
        )

        print("LOG: Revoking subscription for \(sentinelId)")
        send(message: message)
        subscribedSentinels.remove(sentinelId)
        framesBySentinel.removeValue(forKey: sentinelId)
    }

    private func setProfile(for sentinelId: String, profile: String) {
        let message = WebsocketEnvelope(
            type: "proctor.set-profile",
            payload: ProctorSetProfilePayload(sentinelId: sentinelId, profile: profile)
        )
        send(message: message)
    }
    
    func setPinFilter(pin: Int) {
        let message = WebsocketEnvelope(
            type: "proctor.set-pin",
            payload: ProctorSetPinPayload(pin: pin)
        )
        print("LOG: Setting PIN filter to \(pin)")
        send(message: message)
        currentPinFilter = pin
        updateSubscriptions()
    }
    
    func clearPinFilter() {
        print("LOG: Clearing PIN filter")
        currentPinFilter = nil
        updateSubscriptions()
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
    
    func sentinelName(for sentinelId: String) -> String? {
        sentinelList.first { $0.sentinelId == sentinelId }?.name
    }
}
