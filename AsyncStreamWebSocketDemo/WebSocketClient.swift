import Foundation

class WebSocketClient: ObservableObject {
    @MainActor @Published var messages: [String] = []
    @MainActor @Published var isConnected = false
    @MainActor @Published var connectionStatus = "Disconnected"
    
    private let stream: SocketStream?
    
    deinit {
        print("WebSocket client has gone away")
        
        Task { [stream] in
            try await stream?.cancel()
        }
    }
    
    init() {
        let url = URL(string: "ws://127.0.0.1:8080/websocket")!
        let socketConnection = URLSession.shared.webSocketTask(with: url)
        stream = SocketStream(task: socketConnection)
        
        Task { @MainActor [weak self, stream] in
            guard let self = self, let stream = stream else { return }
            
            self.isConnected = true
            self.connectionStatus = "Connected"
            self.messages.append("Connected to WebSocket server")
            
            for try await message in stream {
                if case let .string(string) = message {
                    self.messages.append("Received: \(string)")
                } else if case let .data(data) = message {
                    if let text = String(data: data, encoding: .utf8) {
                        self.messages.append("Received data: \(text)")
                    } else {
                        self.messages.append("Received binary data: \(data.count) bytes")
                    }
                }
            }
            
            // Connection closed
            self.isConnected = false
            self.connectionStatus = "Disconnected"
            self.messages.append("Connection closed")
        }
    }
    
    func send(_ message: String) async {
        guard let stream = stream else { return }
        
        do {
            try await stream.task.send(.string(message))
            await MainActor.run {
                messages.append("Sent: \(message)")
            }
        } catch {
            await MainActor.run {
                messages.append("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    func disconnect() {
        Task {
            try await stream?.cancel()
        }
    }
}

typealias WebSocketStream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>

class SocketStream: AsyncSequence {
    typealias AsyncIterator = WebSocketStream.Iterator
    typealias Element = URLSessionWebSocketTask.Message
    
    let task: URLSessionWebSocketTask
    private let continuation: WebSocketStream.Continuation
    private let stream: WebSocketStream
    
    init(task: URLSessionWebSocketTask) {
        self.task = task
        task.resume()
        
        let pair = WebSocketStream.makeStream()
        self.continuation = pair.continuation
        self.stream = pair.stream
        
        continuation.onTermination = { [weak self] _ in
            Task { [weak self] in
                try await self?.cancel()
            }
        }
        
        Task {
            var isAlive = true
            
            while isAlive && task.closeCode == .invalid {
                do {
                    let value = try await task.receive()
                    pair.continuation.yield(value)
                } catch {
                    pair.continuation.finish(throwing: error)
                    isAlive = false
                }
            }
        }
    }
    
    deinit {
        print("Socket stream deinits")
        continuation.finish()
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        return stream.makeAsyncIterator()
    }
    
    func cancel() async throws {
        print("Canceling WebSocket connection")
        task.cancel(with: .goingAway, reason: nil)
        continuation.finish()
    }
} 