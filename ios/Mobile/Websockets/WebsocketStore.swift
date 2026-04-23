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

struct SentinelFrame: Codable {
    let sentinelId: String
    let data: String
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

enum WebsocketConnectionState: String {
    case disconnected
    case connecting
    case registering
    case connected
    case reconnecting
    case error
}

@Observable
@MainActor
final class WebsocketStore {
    static let shared = WebsocketStore()

    private let url = URL(string: "ws://localhost:5050/api/ws/proctor")!
    private var webSocketTask: URLSessionWebSocketTask?
    private var messageQueue: [String] = []
    private var reconnectTask: Task<Void, Never>?
    private var shouldReconnect = false
    private let reconnectDelayNs: UInt64 = 1_500_000_000

    var connectionState: WebsocketConnectionState = .disconnected
    var framesBySentinel: [String: UIImage] = [:]
    var sentinelList: [SentinelInfo] = []
    var subscribedSentinels = Set<String>()
    private var currentPinFilter: Int?

    var isConnected: Bool {
        connectionState == .connected
    }

    func connectWebsocket() {
        guard webSocketTask == nil else { return }

        shouldReconnect = true
        cancelReconnectTask()

        Task {
            await connectWebsocketAsync(isReconnect: false)
        }
    }

    func disconnect() {
        shouldReconnect = false
        cancelReconnectTask()

        let currentTask = webSocketTask
        webSocketTask = nil
        currentTask?.cancel(with: .normalClosure, reason: nil)

        connectionState = .disconnected
        resetLocalData()
    }

    func subscribe(to sentinelId: String) {
        guard !subscribedSentinels.contains(sentinelId) else { return }

        subscribedSentinels.insert(sentinelId)

        sendEnvelope(
            type: "proctor.subscribe",
            payload: ProctorSubscribePayload(sentinelId: sentinelId)
        )
        setProfile(for: sentinelId, profile: "LOW")
    }

    func revokeSubscription(_ sentinelId: String) {
        guard subscribedSentinels.contains(sentinelId) else { return }

        subscribedSentinels.remove(sentinelId)
        sendEnvelope(
            type: "proctor.revoke-subscription",
            payload: ProctorSubscribePayload(sentinelId: sentinelId)
        )
        framesBySentinel.removeValue(forKey: sentinelId)
    }

    func setPinFilter(pin: Int) {
        currentPinFilter = pin

        sendEnvelope(
            type: "proctor.set-pin",
            payload: ProctorSetPinPayload(pin: pin)
        )

        updateSubscriptions()
    }

    func clearPinFilter() {
        currentPinFilter = nil
        updateSubscriptions()
    }

    func sentinelName(for sentinelId: String) -> String? {
        sentinelList.first { $0.sentinelId == sentinelId }?.name
    }

    private func connectWebsocketAsync(isReconnect: Bool) async {
        print("LOG: [Websocket] connectWebsocketAsync (isReconnect: \(isReconnect)) url: \(url)")
        connectionState = isReconnect ? .reconnecting : .connecting

        guard let token = await LoginService.shared.getValidAccessToken() else {
            print("LOG: [Websocket] Failed to get valid access token")
            connectionState = .error
            scheduleReconnect()
            return
        }
        print("LOG: [Websocket] Got token, initiating connection...")

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let task = URLSession.shared.webSocketTask(with: request)
        webSocketTask = task
        task.resume()

        connectionState = .registering
        receiveMessageLoop(for: task)

        let register = WebsocketEnvelope(
            type: "proctor.register",
            payload: ProctorRegisterPayload(auth: token)
        )
        
        if let data = try? JSONEncoder().encode(register),
           let text = String(data: data, encoding: .utf8) {
            print("LOG: [Websocket] Sending register message directly")
            task.send(.string(text)) { [weak self] error in
                if let error = error {
                    print("LOG: [Websocket] Register send error: \(error)")
                    Task { @MainActor in
                        self?.connectionState = .error
                        self?.scheduleReconnect()
                    }
                }
            }
        }
    }

    private func sendEnvelope<Payload: Codable>(type: String, payload: Payload) {
        let envelope = WebsocketEnvelope(type: type, payload: payload)
        send(message: envelope)
    }

    private func send<Message: Encodable>(message: Message) {
        guard let data = try? JSONEncoder().encode(message),
              let text = String(data: data, encoding: .utf8)
        else {
            print("LOG: [Websocket] Failed to encode message")
            return
        }
        print("LOG: [Websocket] Sending: \(text.prefix(150))")

        guard let task = webSocketTask else {
            print("LOG: [Websocket] Socket not active, queueing message")
            messageQueue.append(text)
            return
        }

        guard isConnected else {
            messageQueue.append(text)
            return
        }

        task.send(.string(text)) { [weak self] error in
            guard let self else { return }

            if error != nil {
                Task { @MainActor in
                    self.messageQueue.append(text)
                    self.connectionState = .error
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func receiveMessageLoop(for task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let message):
                    guard self.webSocketTask === task else { return }

                    if case .string(let text) = message {
                        self.handleIncomingText(text)
                    }
                    self.receiveMessageLoop(for: task)

                case .failure:
                    guard self.webSocketTask === task else { return }

                    self.webSocketTask = nil
                    if self.shouldReconnect {
                        self.connectionState = .reconnecting
                        self.scheduleReconnect()
                    } else {
                        self.connectionState = .disconnected
                    }
                }
            }
        }
    }

    private func handleIncomingText(_ text: String) {
        print("LOG: [Websocket] Received message prefix: \(text.prefix(200))")
        guard let data = text.data(using: .utf8) else { return }

        do {
            let serverMessage = try JSONDecoder().decode(ServerMessage.self, from: data)

            if serverMessage.type == "server.registration.ack" {
                onRegistered()
                return
            }

            if serverMessage.type == "server.registration.reject" {
                connectionState = .error
                disconnect()
                return
            }

            if serverMessage.type == "server.frame", let frames = serverMessage.payload.frames {
                updateFrames(frames)
                return
            }

            if serverMessage.type == "server.update-sentinels", let sentinels = serverMessage.payload.sentinels {
                print("LOG: [Websocket] Received update-sentinels with count: \(sentinels.count)")
                updateLocalSentinels(sentinels)
                updateSubscriptions()
                return
            }

            if serverMessage.type == "server.sentinel-disconnected", let sentinelId = serverMessage.payload.sentinelId {
                framesBySentinel.removeValue(forKey: sentinelId)
                subscribedSentinels.remove(sentinelId)
                sentinelList.removeAll { $0.sentinelId == sentinelId }
            }
        } catch {
            print("LOG: [Websocket] Decode error: \(error)")
            // Ignore malformed payloads but keep socket alive.
        }
    }

    private func onRegistered() {
        connectionState = .connected

        if let pin = currentPinFilter {
            sendEnvelope(type: "proctor.set-pin", payload: ProctorSetPinPayload(pin: pin))
        }

        for sentinelId in subscribedSentinels {
            sendEnvelope(type: "proctor.subscribe", payload: ProctorSubscribePayload(sentinelId: sentinelId))
            setProfile(for: sentinelId, profile: "LOW")
        }

        flushMessageQueue()
    }

    private func flushMessageQueue() {
        guard isConnected, let task = webSocketTask else { return }

        while !messageQueue.isEmpty {
            let message = messageQueue.removeFirst()
            task.send(.string(message)) { [weak self] error in
                guard let self else { return }

                if error != nil {
                    Task { @MainActor in
                        self.messageQueue.insert(message, at: 0)
                        self.connectionState = .error
                        self.scheduleReconnect()
                    }
                }
            }
        }
    }

    private func updateLocalSentinels(_ newSentinels: [SentinelInfo]) {
        let newIds = Set(newSentinels.map { $0.sentinelId })

        sentinelList = sentinelList.filter { newIds.contains($0.sentinelId) }

        let existingIds = Set(sentinelList.map { $0.sentinelId })
        let toAdd = newSentinels.filter { !existingIds.contains($0.sentinelId) }
        sentinelList.append(contentsOf: toAdd)

        for existingId in Array(framesBySentinel.keys) where !newIds.contains(existingId) {
            framesBySentinel.removeValue(forKey: existingId)
            subscribedSentinels.remove(existingId)
        }
    }

    private func updateFrames(_ frames: [SentinelFrame]) {
        for frame in frames {
            if let image = convertBase64ToImage(frame.data) {
                framesBySentinel[frame.sentinelId] = image
            }
        }
    }

    private func convertBase64ToImage(_ base64String: String) -> UIImage? {
        let cleanString = base64String.components(separatedBy: ",").last ?? base64String
        guard let data = Data(base64Encoded: cleanString) else { return nil }
        return UIImage(data: data)
    }

    private func setProfile(for sentinelId: String, profile: String) {
        sendEnvelope(
            type: "proctor.set-profile",
            payload: ProctorSetProfilePayload(sentinelId: sentinelId, profile: profile)
        )
    }

    private func updateSubscriptions() {
        let activeSentinelIds = Set(sentinelList.map { $0.sentinelId })

        for subscribedId in subscribedSentinels where !activeSentinelIds.contains(subscribedId) {
            revokeSubscription(subscribedId)
        }

        for sentinelId in activeSentinelIds {
            subscribe(to: sentinelId)
        }
    }

    private func scheduleReconnect() {
        guard shouldReconnect, reconnectTask == nil else { return }

        reconnectTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: reconnectDelayNs)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.reconnectTask = nil
                if self.shouldReconnect {
                    Task {
                        await self.connectWebsocketAsync(isReconnect: true)
                    }
                }
            }
        }
    }

    private func cancelReconnectTask() {
        reconnectTask?.cancel()
        reconnectTask = nil
    }

    private func resetLocalData() {
        framesBySentinel.removeAll()
        sentinelList.removeAll()
        subscribedSentinels.removeAll()
        currentPinFilter = nil
        messageQueue.removeAll()
    }
}
