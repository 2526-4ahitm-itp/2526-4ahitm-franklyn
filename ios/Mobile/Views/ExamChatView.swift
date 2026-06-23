import Combine
import SwiftUI

// MARK: - Model

struct ChatMessage: Identifiable {
    let id: UUID
    var serverId: String?
    let text: String
    let timestamp: Date
    var status: Status

    enum Status { case sending, sent, received, failed }

    init(text: String, timestamp: Date, status: Status) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.status = status
    }
}

// MARK: - ViewModel

@MainActor
final class ExamChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []

    private let examId: String
    private var wsTask: URLSessionWebSocketTask?
    private var earlyConfirmations: Set<String> = []

    init(examId: String) {
        self.examId = examId
    }

    // MARK: WebSocket

    func connect() {
        guard let url = URL(string: "ws://127.0.0.1:8000/api/ws/chat") else { return }
        wsTask = URLSession.shared.webSocketTask(with: url)
        wsTask?.resume()
        log("WS connecting to \(url)")
        sendJoin()
        receiveLoop()
    }

    func disconnect() {
        wsTask?.cancel(with: .goingAway, reason: nil)
        log("WS disconnected")
    }

    private func sendJoin() {
        let frame: [String: Any] = [
            "type": "chat.join",
            "timestamp": 0,
            "payload": ["examId": examId]
        ]
        sendWSFrame(frame) { self.log("WS chat.join sent for room '\(self.examId)'") }
    }

    private func sendWSFrame(_ dict: [String: Any], onSuccess: @escaping () -> Void) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return }
        wsTask?.send(.string(str)) { [weak self] error in
            if let error {
                self?.log("WS send error: \(error.localizedDescription)")
            } else {
                onSuccess()
            }
        }
    }

    private func receiveLoop() {
        wsTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.log("WS receive error: \(error.localizedDescription)")
            case .success(let message):
                let raw: String?
                switch message {
                case .string(let str): raw = str
                case .data(let data): raw = String(data: data, encoding: .utf8)
                @unknown default: raw = nil
                }
                if let raw {
                    Task { @MainActor in self.handleFrame(raw) }
                }
                self.receiveLoop()
            }
        }
    }

    private func handleFrame(_ raw: String) {
        log("WS ← \(raw)")
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            log("WS could not parse frame")
            return
        }

        switch type {
        case "chat.history":
            let historyMessages = (json["payload"] as? [String: Any])
                .flatMap { $0["messages"] as? [[String: Any]] } ?? []
            log("WS chat.history: \(historyMessages.count) message(s)")
            let loaded: [ChatMessage] = historyMessages.compactMap { dict in
                guard let serverId = dict["id"] as? String,
                      let text = dict["text"] as? String else { return nil }
                let ts = (dict["timestamp"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
                var msg = ChatMessage(text: text, timestamp: ts, status: .received)
                msg.serverId = serverId
                return msg
            }
            messages = loaded

        case "chat.message":
            guard let payload = json["payload"] as? [String: Any],
                  let serverId = payload["id"] as? String else { return }
            log("WS chat.message — serverId: \(serverId)")
            applyConfirmation(serverId: serverId)

        case "chat.read_receipt":
            log("WS chat.read_receipt")

        case "chat.error":
            let reason = (json["payload"] as? [String: Any])?["reason"] as? String ?? "unknown"
            log("WS chat.error: \(reason)")

        default:
            log("WS unknown event: '\(type)'")
        }
    }

    private func applyConfirmation(serverId: String) {
        if let idx = messages.firstIndex(where: { $0.serverId == serverId }) {
            log("message '\(messages[idx].text)' → received")
            withAnimation { messages[idx].status = .received }
        } else {
            log("WS confirmation arrived before HTTP response — buffering \(serverId)")
            earlyConfirmations.insert(serverId)
        }
    }

    // MARK: Send

    func send(text: String) {
        let message = ChatMessage(text: text, timestamp: Date(), status: .sending)
        let messageId = message.id
        messages.append(message)
        log("message queued (id: \(messageId)) — status: sending")

        Task {
            do {
                let serverId = try await postMessage(text: text)
                log("HTTP 200 — serverId: \(serverId), status: sent")
                guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
                messages[idx].serverId = serverId
                if earlyConfirmations.remove(serverId) != nil {
                    log("applied buffered WS confirmation — '\(messages[idx].text)' → received")
                    withAnimation { messages[idx].status = .received }
                } else {
                    withAnimation { messages[idx].status = .sent }
                }
            } catch {
                log("HTTP error: \(error.localizedDescription) — status: failed")
                guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
                withAnimation { messages[idx].status = .failed }
            }
        }
    }

    private func postMessage(text: String) async throws -> String {
        guard let url = URL(string: "http://127.0.0.1:8000/api/chat/message") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "examId": examId,
            "message": text
        ])
        log("POST \(url) — examId: \(examId)")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        log("POST response HTTP \(http.statusCode)")
        guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let msg = json["message"] as? [String: Any],
              let serverId = msg["id"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        return serverId
    }

    private func log(_ msg: String) {
        print("[Chat] \(msg)")
    }
}

// MARK: - View

struct ExamChatView: View {
    @StateObject private var vm: ExamChatViewModel
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    init(examId: String) {
        _vm = StateObject(wrappedValue: ExamChatViewModel(examId: examId))
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputBar
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear { vm.connect() }
        .onDisappear { vm.disconnect() }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(vm.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .onChange(of: vm.messages.count) {
                guard let last = vm.messages.last else { return }
                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)

                Button { send() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(canSend ? Color.blue : Color.secondary)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(uiColor: .systemBackground))
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        vm.send(text: text)
    }
}

// MARK: - Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Spacer(minLength: 60)
            VStack(alignment: .trailing, spacing: 3) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack(spacing: 3) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    statusIcon
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .received:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.blue)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }
}
