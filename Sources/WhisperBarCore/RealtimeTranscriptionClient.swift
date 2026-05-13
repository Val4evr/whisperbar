import Foundation

public protocol RealtimeTranscriptionClientDelegate: AnyObject, Sendable {
    func realtimeClient(_ client: RealtimeTranscriptionClient, didReceive event: RealtimeTranscriptionEvent)
    func realtimeClient(_ client: RealtimeTranscriptionClient, didFail error: Error)
}

public final class RealtimeTranscriptionClient: @unchecked Sendable {
    public weak var delegate: RealtimeTranscriptionClientDelegate?

    private let apiKey: String
    private let url: URL
    private let session: URLSession
    private var webSocket: URLSessionWebSocketTask?
    private let queue = DispatchQueue(label: "ai.valprok.WhisperBar.realtime")
    private var isConnected = false

    public init(apiKey: String, url: URL = AppConstants.realtimeTranscriptionURL, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.url = url
        self.session = session
    }

    public func connect() {
        queue.async {
            guard self.webSocket == nil else { return }
            var request = URLRequest(url: self.url)
            request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
            let socket = self.session.webSocketTask(with: request)
            self.webSocket = socket
            self.isConnected = true
            socket.resume()
            self.receiveLoop()
            self.sendData(try! RealtimeRequestFactory.sessionUpdate())
        }
    }

    public func appendAudio(_ data: Data) {
        queue.async {
            guard self.isConnected else { return }
            do {
                self.sendData(try RealtimeRequestFactory.appendAudio(data))
            } catch {
                self.delegate?.realtimeClient(self, didFail: error)
            }
        }
    }

    public func commit() {
        queue.async {
            guard self.isConnected else { return }
            do {
                self.sendData(try RealtimeRequestFactory.commitAudio())
            } catch {
                self.delegate?.realtimeClient(self, didFail: error)
            }
        }
    }

    public func disconnect() {
        queue.async {
            self.isConnected = false
            self.webSocket?.cancel(with: .normalClosure, reason: nil)
            self.webSocket = nil
        }
    }

    private func sendData(_ data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        webSocket?.send(.string(text)) { [weak self] error in
            guard let self, let error else { return }
            self.delegate?.realtimeClient(self, didFail: error)
        }
    }

    private func receiveLoop() {
        webSocket?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                do {
                    let data: Data
                    switch message {
                    case .data(let payload):
                        data = payload
                    case .string(let text):
                        data = Data(text.utf8)
                    @unknown default:
                        data = Data()
                    }
                    if !data.isEmpty {
                        let event = try RealtimeTranscriptionEventParser.parse(data)
                        self.delegate?.realtimeClient(self, didReceive: event)
                    }
                } catch {
                    self.delegate?.realtimeClient(self, didFail: error)
                }
                if self.isConnected {
                    self.receiveLoop()
                }
            case .failure(let error):
                if self.isConnected {
                    self.delegate?.realtimeClient(self, didFail: error)
                }
            }
        }
    }
}
