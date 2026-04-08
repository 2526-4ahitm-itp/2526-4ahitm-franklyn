//
//  WebsocketStore.swift
//  Mobile
//
//  Created by Clemens Zangenfeind on 08.04.26.
//

import Foundation

import Foundation

// 1. Define the URL (use a public echo server for testing)
let url = URL(string: "wss://echo.websocket.org")!

// 2. Create the session and the task
let session = URLSession(configuration: .default)
let webSocketTask = session.webSocketTask(with: url)

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

    func connectWebsocket() {
        webSocketTask.resume()
        print("Connecting...")
    }
    
    func receiveFrame() {
            webSocketTask.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("Received string: \(text)")
                    case .data(let data):
                        print("Received binary data: \(data.count) bytes")
                    @unknown default:
                        break
                    }

                    self.receiveFrame()
                    
                case .failure(let error):
                    print("Receive error: \(error.localizedDescription)")
                }
            }
    }

}
