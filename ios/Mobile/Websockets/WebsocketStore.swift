//
//  WebsocketStore.swift
//  Mobile
//
//  Created by Clemens Zangenfeind on 08.04.26.
//

import Foundation
import Observation
import SwiftUI

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
    }
}

// The registration message we send to the server
struct ProctorRegister: Codable {
    let type: String = "proctor.register"
    let timestamp: Int = Int(Date().timeIntervalSince1970)
}

@Observable
class WebsocketStore {
    let url = URL(string: "localhost:5050/ws/proctor")!
    var webSocketTask : URLSessionWebSocketTask?

    var framesBySentinel: [String: UIImage] = [:]

    func connectWebsocket() {
        var request = URLRequest(url: url)
        let subProtocol = "bearer-token-carrier"
            request.setValue(subProtocol, forHTTPHeaderField: "Sec-WebSocket-Protocol")
        
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        print("LOG: WebSocket Task Created. Calling resume()...")
        webSocketTask?.resume()
        print("Connecting...")
        
        sendRegisterMessage()
        
        receiveMessage()
    }
    
    private func sendRegisterMessage() {
            let register = ProctorRegister()
            if let jsonData = try? JSONEncoder().encode(register),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                webSocketTask?.send(.string(jsonString)) { error in
                    if let error = error { print("Registration error: \(error)") }
                }
            }
        }
        
        private func receiveMessage() {
            webSocketTask?.receive { [weak self] result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self?.handleIncomingText(text)
                    default:
                        break
                    }
                    self?.receiveMessage()
                    
                case .failure(let error):
                    print("WebSocket Disconnected: \(error)")
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
                        for frame in frames {
                            if let image = convertBase64ToImage(frame.data) {
                                self.framesBySentinel[frame.sentinelId] = image
                            }
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
        let message: [String: Any] = [
            "type": "proctor.subscribe",
            "payload": ["sentinelId": sentinelId],
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocketTask?.send(.string(jsonString)) { _ in }
        }
    }
}
