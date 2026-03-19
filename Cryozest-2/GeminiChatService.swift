import Foundation

struct ChatMessage: Identifiable {
    let id: UUID
    let role: ChatRole
    var content: String
    let timestamp: Date
    var blocks: [CoachResponseBlock]?
    var followUpSuggestions: [String]
    var originalPrompt: String?
    var feedback: Feedback?

    enum ChatRole: String {
        case user
        case model
    }

    enum Feedback: String, Codable {
        case thumbsUp
        case thumbsDown
    }

    init(role: ChatRole, content: String, blocks: [CoachResponseBlock]? = nil, followUpSuggestions: [String] = [], timestamp: Date = Date(), feedback: Feedback? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.blocks = blocks
        self.followUpSuggestions = followUpSuggestions
        self.feedback = feedback
    }
}

enum ChatServiceError: LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(String)
    case apiError(Int)
    case parseError
    case timeout

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "AI Coach is not configured. Add a Gemini API key to Secrets.plist."
        case .invalidURL:
            return "Internal error building request."
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let code):
            return "API error (status \(code)). Try again later."
        case .parseError:
            return "Couldn't parse AI response. Try again."
        case .timeout:
            return "Request timed out. Check your connection and try again."
        }
    }
}

class GeminiChatService: NSObject {
    private let modelName = "gemini-2.5-flash"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let maxHistoryMessages = 20

    private var apiKey: String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let key = dict["GeminiAPIKey"] as? String,
              !key.isEmpty else {
            return nil
        }
        return key
    }

    var isConfigured: Bool { apiKey != nil }

    // MARK: - Build request body (shared between streaming and non-streaming)

    private func buildRequestBody(
        userMessage: String,
        conversationHistory: [ChatMessage],
        healthContext: String
    ) -> [String: Any] {
        var contents: [[String: Any]] = []

        let recentHistory = conversationHistory.suffix(maxHistoryMessages)
        for message in recentHistory {
            contents.append([
                "role": message.role.rawValue,
                "parts": [["text": message.content]]
            ])
        }

        contents.append([
            "role": "user",
            "parts": [["text": userMessage]]
        ])

        return [
            "systemInstruction": [
                "parts": [["text": healthContext]]
            ],
            "contents": contents,
            "generationConfig": [
                "maxOutputTokens": 2000,
                "temperature": 0.7
            ]
        ]
    }

    // MARK: - Streaming API (SSE)

    /// Stream a response from Gemini. Calls `onChunk` with each text delta as it arrives.
    /// Returns the full accumulated response when complete.
    func streamMessage(
        userMessage: String,
        conversationHistory: [ChatMessage],
        healthContext: String,
        onChunk: @escaping (String) -> Void
    ) async throws -> String {
        guard let apiKey = apiKey else {
            throw ChatServiceError.noAPIKey
        }

        // Use streamGenerateContent endpoint with alt=sse for server-sent events
        guard let url = URL(string: "\(baseURL)/\(modelName):streamGenerateContent?alt=sse&key=\(apiKey)") else {
            throw ChatServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body = buildRequestBody(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            healthContext: healthContext
        )

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            throw ChatServiceError.invalidURL
        }
        request.httpBody = httpBody

        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await URLSession.shared.bytes(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw ChatServiceError.timeout
        } catch {
            throw ChatServiceError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatServiceError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw ChatServiceError.apiError(httpResponse.statusCode)
        }

        // Parse SSE stream: lines starting with "data: " contain JSON chunks
        var fullText = ""

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))
            guard !jsonString.isEmpty, jsonString != "[DONE]" else { continue }

            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                continue
            }

            fullText += text
            onChunk(text)
        }

        if fullText.isEmpty {
            throw ChatServiceError.parseError
        }

        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Non-streaming fallback

    func sendMessage(
        userMessage: String,
        conversationHistory: [ChatMessage],
        healthContext: String
    ) async throws -> String {
        guard let apiKey = apiKey else {
            throw ChatServiceError.noAPIKey
        }

        guard let url = URL(string: "\(baseURL)/\(modelName):generateContent?key=\(apiKey)") else {
            throw ChatServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = buildRequestBody(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            healthContext: healthContext
        )

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            throw ChatServiceError.invalidURL
        }
        request.httpBody = httpBody

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw ChatServiceError.timeout
        } catch {
            throw ChatServiceError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatServiceError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw ChatServiceError.apiError(httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw ChatServiceError.parseError
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
