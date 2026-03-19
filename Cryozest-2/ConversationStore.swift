import Foundation

struct SavedMessage: Codable {
    let role: String
    let content: String
    let timestamp: Date
    let feedback: String? // "thumbsUp" or "thumbsDown"
}

struct SavedConversation: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    var messages: [SavedMessage]

    var preview: String {
        messages.first(where: { $0.role == "user" })?.content ?? "Conversation"
    }
}

class ConversationStore: ObservableObject {
    static let shared = ConversationStore()

    @Published var recentConversations: [SavedConversation] = []

    private let maxConversations = 20
    private var currentConversationId: UUID?

    private var directoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("coach_conversations")
    }

    init() {
        ensureDirectory()
        loadConversationList()
    }

    private func ensureDirectory() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func saveConversation(_ messages: [ChatMessage]) {
        guard !messages.isEmpty else { return }

        let id = currentConversationId ?? UUID()
        currentConversationId = id

        let saved = SavedConversation(
            id: id,
            createdAt: messages.first?.timestamp ?? Date(),
            messages: messages.map { msg in
                SavedMessage(
                    role: msg.role.rawValue,
                    content: msg.content,
                    timestamp: msg.timestamp,
                    feedback: msg.feedback?.rawValue
                )
            }
        )

        let fileURL = directoryURL.appendingPathComponent("\(id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(saved) {
            try? data.write(to: fileURL)
        }

        loadConversationList()
    }

    func startNewConversation() {
        currentConversationId = nil
    }

    func loadConversationList() {
        ensureDirectory()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            recentConversations = []
            return
        }

        var conversations: [SavedConversation] = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(SavedConversation.self, from: data)
            }
            .sorted { $0.createdAt > $1.createdAt }

        // Auto-prune to last 20
        if conversations.count > maxConversations {
            let toRemove = conversations[maxConversations...]
            for conv in toRemove {
                let fileURL = directoryURL.appendingPathComponent("\(conv.id.uuidString).json")
                try? FileManager.default.removeItem(at: fileURL)
            }
            conversations = Array(conversations.prefix(maxConversations))
        }

        recentConversations = conversations
    }

    func loadConversation(id: UUID) -> SavedConversation? {
        let fileURL = directoryURL.appendingPathComponent("\(id.uuidString).json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(SavedConversation.self, from: data)
    }
}
