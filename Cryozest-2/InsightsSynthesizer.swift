import Foundation
import CoreData

/// Calls Gemini 3.0 Flash to synthesize natural-language health insights
/// from the user's correlation data, recent habits, and health metrics.
class InsightsSynthesizer: ObservableObject {
    static let shared = InsightsSynthesizer()

    @Published var synthesizedInsight: String?
    @Published var isLoading = false

    private let modelName = "gemini-2.5-flash"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    // MARK: - API Key

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

    // MARK: - Cache (per-day, persists across app restarts)

    private let cacheKey = "synthesized_insight_v2"
    private let cacheDateKey = "synthesized_insight_v2_date"

    private func cachedInsight() -> String? {
        let today = todayKey()
        guard UserDefaults.standard.string(forKey: cacheDateKey) == today else { return nil }
        return UserDefaults.standard.string(forKey: cacheKey)
    }

    private func cacheInsight(_ text: String) {
        UserDefaults.standard.set(text, forKey: cacheKey)
        UserDefaults.standard.set(todayKey(), forKey: cacheDateKey)
    }

    // MARK: - Public API

    /// Generate a natural-language insight from the user's health data.
    /// Falls back to nil if no API key or on error — caller should use template fallback.
    func generateInsight(
        impacts: [HabitImpact],
        healthTrends: [HealthTrend],
        recentHabits: [(name: String, count: Int, streak: Int)],
        sleepHours: String?,
        hrv: String?,
        rhr: String?,
        steps: String?
    ) async -> String? {
        // Return cache if available
        if let cached = cachedInsight() {
            await MainActor.run { self.synthesizedInsight = cached }
            return cached
        }

        guard let apiKey = apiKey else { return nil }

        await MainActor.run { self.isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        let prompt = buildPrompt(
            impacts: impacts,
            healthTrends: healthTrends,
            recentHabits: recentHabits,
            sleepHours: sleepHours,
            hrv: hrv,
            rhr: rhr,
            steps: steps
        )

        guard let url = URL(string: "\(baseURL)/\(modelName):generateContent?key=\(apiKey)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 25

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 200,
                "temperature": 0.7
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("InsightsSynthesizer: Invalid response type")
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? "nil"
                print("InsightsSynthesizer: API returned \(httpResponse.statusCode): \(body.prefix(200))")
                return nil
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("InsightsSynthesizer: Failed to parse response JSON")
                return nil
            }

            // Check for blocked responses
            if let candidates = json["candidates"] as? [[String: Any]],
               let finishReason = candidates.first?["finishReason"] as? String,
               finishReason != "STOP" {
                print("InsightsSynthesizer: Response blocked with reason: \(finishReason)")
            }

            if let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                // Quality gate: reject short, incomplete, or truncated responses
                let wordCount = trimmed.split(separator: " ").count
                let endChars: Set<Character> = [".", "!", "?", "\"", "'", ")", "\u{201D}", "\u{2019}"]
                let endsWithPunctuation = trimmed.last.map { endChars.contains($0) } ?? false
                guard trimmed.count >= 30, wordCount >= 6, endsWithPunctuation else {
                    print("InsightsSynthesizer: Response failed quality gate (\(trimmed.count) chars, \(wordCount) words, ends with punct: \(endsWithPunctuation)), skipping: \(trimmed)")
                    return nil
                }
                cacheInsight(trimmed)
                await MainActor.run { self.synthesizedInsight = trimmed }
                print("InsightsSynthesizer: Generated insight (\(trimmed.count) chars)")
                return trimmed
            } else {
                print("InsightsSynthesizer: Could not extract text from response: \(String(data: data, encoding: .utf8)?.prefix(300) ?? "nil")")
            }
        } catch {
            print("InsightsSynthesizer error: \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - What's Working Insight

    private let whatsWorkingCacheKey = "whats_working_v1"
    private let whatsWorkingCacheDateKey = "whats_working_v1_date"

    private func cachedWhatsWorkingInsight() -> String? {
        let today = todayKey()
        guard UserDefaults.standard.string(forKey: whatsWorkingCacheDateKey) == today else { return nil }
        return UserDefaults.standard.string(forKey: whatsWorkingCacheKey)
    }

    private func cacheWhatsWorkingInsight(_ text: String) {
        UserDefaults.standard.set(text, forKey: whatsWorkingCacheKey)
        UserDefaults.standard.set(todayKey(), forKey: whatsWorkingCacheDateKey)
    }

    /// Generate a comprehensive "what's working" summary that synthesizes across ALL metrics and habits.
    func generateWhatsWorkingInsight(
        impacts: [HabitImpact],
        healthTrends: [HealthTrend],
        recentHabits: [(name: String, count: Int, streak: Int)],
        sleepHours: String?,
        hrv: String?,
        rhr: String?
    ) async -> String? {
        if let cached = cachedWhatsWorkingInsight() {
            return cached
        }

        guard let apiKey = apiKey else { return nil }
        guard !impacts.isEmpty else { return nil }

        let prompt = buildWhatsWorkingPrompt(
            impacts: impacts,
            healthTrends: healthTrends,
            recentHabits: recentHabits,
            sleepHours: sleepHours,
            hrv: hrv,
            rhr: rhr
        )

        guard let url = URL(string: "\(baseURL)/\(modelName):generateContent?key=\(apiKey)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 25

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "maxOutputTokens": 250,
                "temperature": 0.7
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                print("InsightsSynthesizer: WhatsWorking API failed")
                return nil
            }

            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let wordCount = trimmed.split(separator: " ").count
            let endChars: Set<Character> = [".", "!", "?", "\"", "'", ")", "\u{201D}", "\u{2019}"]
            let endsWithPunctuation = trimmed.last.map { endChars.contains($0) } ?? false
            guard trimmed.count >= 30, wordCount >= 8, endsWithPunctuation else {
                print("InsightsSynthesizer: WhatsWorking failed quality gate")
                return nil
            }

            cacheWhatsWorkingInsight(trimmed)
            print("InsightsSynthesizer: Generated WhatsWorking insight (\(trimmed.count) chars)")
            return trimmed
        } catch {
            print("InsightsSynthesizer: WhatsWorking error: \(error.localizedDescription)")
            return nil
        }
    }

    private func buildWhatsWorkingPrompt(
        impacts: [HabitImpact],
        healthTrends: [HealthTrend],
        recentHabits: [(name: String, count: Int, streak: Int)],
        sleepHours: String?,
        hrv: String?,
        rhr: String?
    ) -> String {
        var sections: [String] = []

        sections.append("""
        You are a health insights assistant inside a personal health tracking app. \
        Write a brief, comprehensive summary (2-4 sentences, 40-80 words) of what's working and what to watch in this user's routine. \
        Synthesize ACROSS metrics — don't just name one habit. Connect the dots: which habits drive which outcomes, \
        and how do the metrics relate to each other. \
        Use arrows (→) for cause-effect. Include specific percentages from the data. \
        Sound like a smart coach who analyzed everything. No disclaimers. No generic advice. \
        If there are negative correlations, briefly mention the most important one. \
        End with one actionable takeaway.
        """)

        // All correlations (positive and negative)
        let positiveImpacts = impacts.filter { $0.isPositive }
        let negativeImpacts = impacts.filter { !$0.isPositive }

        if !positiveImpacts.isEmpty {
            let lines = positiveImpacts.prefix(6).map { impact in
                let pct = abs(Int(impact.percentageChange))
                return "- \(impact.habitType.rawValue) → \(impact.metricName) improved \(pct)% (n=\(impact.sampleSize), confidence=\(impact.confidenceLevel.rawValue))"
            }
            sections.append("POSITIVE CORRELATIONS:\n" + lines.joined(separator: "\n"))
        }

        if !negativeImpacts.isEmpty {
            let lines = negativeImpacts.prefix(3).map { impact in
                let pct = abs(Int(impact.percentageChange))
                return "- \(impact.habitType.rawValue) → \(impact.metricName) worsened \(pct)% (n=\(impact.sampleSize))"
            }
            sections.append("NEGATIVE CORRELATIONS (worth mentioning):\n" + lines.joined(separator: "\n"))
        }

        // Week-over-week trends
        if !healthTrends.isEmpty {
            let trendLines = healthTrends.prefix(4).map { trend in
                let dir = trend.changePercentage >= 0 ? "up" : "down"
                return "- \(trend.metric): \(dir) \(abs(Int(trend.changePercentage)))% vs last week"
            }
            sections.append("THIS WEEK'S TRENDS:\n" + trendLines.joined(separator: "\n"))
        }

        // Today's vitals
        var metricsLines: [String] = []
        if let s = sleepHours, s != "--" { metricsLines.append("Sleep: \(s) hrs") }
        if let h = hrv, h != "--" { metricsLines.append("HRV: \(h) ms") }
        if let r = rhr, r != "--" { metricsLines.append("RHR: \(r) bpm") }
        if !metricsLines.isEmpty {
            sections.append("TODAY'S VITALS: " + metricsLines.joined(separator: " · "))
        }

        // Streaks/frequency
        let activeHabits = recentHabits.filter { $0.count > 0 }
        if !activeHabits.isEmpty {
            let lines = activeHabits.map { h in
                var line = "- \(h.name): \(h.count)x this week"
                if h.streak > 1 { line += " (\(h.streak)-day streak)" }
                return line
            }
            sections.append("RECENT ACTIVITY:\n" + lines.joined(separator: "\n"))
        }

        sections.append("Write the summary now. Synthesize across all data — don't just repeat one correlation.")
        return sections.joined(separator: "\n\n")
    }

    // MARK: - Prompt Construction

    private func buildPrompt(
        impacts: [HabitImpact],
        healthTrends: [HealthTrend],
        recentHabits: [(name: String, count: Int, streak: Int)],
        sleepHours: String?,
        hrv: String?,
        rhr: String?,
        steps: String?
    ) -> String {
        var sections: [String] = []

        // Context
        sections.append("""
        You are a health insights assistant inside a personal health tracking app. \
        The user tracks daily habits and wears an Apple Watch. \
        Based on the data below, write ONE concise, personal insight (2-3 sentences). \
        Be specific — always include the actual numbers from their data. \
        Be direct — no fluff, no disclaimers, no generic advice. \
        Sound like a smart friend who looked at your data, not a doctor or a chatbot. \
        If a correlation exists, explain it with an arrow (→) showing cause and effect. \
        If data is limited, focus on the most interesting metric you can see. \
        Never refer to raw numbers without context (e.g. say "7.2 hours of sleep" not just "7.2").
        """)

        // Today's health metrics
        var metricsLines: [String] = []
        if let s = sleepHours, s != "--" { metricsLines.append("Sleep last night: \(s) hrs") }
        if let h = hrv, h != "--" { metricsLines.append("HRV: \(h) ms") }
        if let r = rhr, r != "--" { metricsLines.append("Resting HR: \(r) bpm") }
        if let st = steps, st != "--" { metricsLines.append("Steps: \(st)") }
        if !metricsLines.isEmpty {
            sections.append("TODAY'S HEALTH METRICS:\n" + metricsLines.joined(separator: "\n"))
        }

        // Recent habits
        if !recentHabits.isEmpty {
            let habitLines = recentHabits.map { habit in
                var line = "- \(habit.name): \(habit.count)x this week"
                if habit.streak > 1 { line += " (\(habit.streak)-day streak)" }
                return line
            }
            sections.append("HABITS THIS WEEK:\n" + habitLines.joined(separator: "\n"))
        }

        // Top correlations (the statistical findings)
        let coreImpacts = impacts.filter { ["Sleep Duration", "HRV", "RHR"].contains($0.metricName) }
        if !coreImpacts.isEmpty {
            let impactLines = coreImpacts.prefix(6).map { impact in
                let direction = impact.isPositive ? "improved" : "worsened"
                let confidence = impact.confidenceLevel.rawValue
                return "- \(impact.habitType.rawValue) → \(impact.metricName) \(direction) by \(abs(Int(impact.percentageChange)))% (confidence: \(confidence), n=\(impact.sampleSize))"
            }
            sections.append("STATISTICAL CORRELATIONS (Pearson, from your data):\n" + impactLines.joined(separator: "\n"))
        }

        // Week-over-week trends
        if !healthTrends.isEmpty {
            let trendLines = healthTrends.prefix(4).map { trend in
                let dir = trend.changePercentage >= 0 ? "up" : "down"
                return "- \(trend.metric): \(dir) \(abs(Int(trend.changePercentage)))% vs last week"
            }
            sections.append("WEEK-OVER-WEEK TRENDS:\n" + trendLines.joined(separator: "\n"))
        }

        sections.append("Write the insight now. Aim for 20-50 words. No bullet points. Must reference specific numbers from the data above.")

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Correlation Validation

    /// Sends raw correlations to Gemini to filter out nonsensical ones and rank the rest.
    /// Returns indices of correlations that pass the sanity check, ranked best-first.
    func validateCorrelations(_ correlations: [HabitImpact]) async -> [Int] {
        guard let apiKey = apiKey, !correlations.isEmpty else {
            return Array(correlations.indices)
        }

        let lines = correlations.enumerated().map { i, c in
            let dir = c.isPositive ? "improves" : "worsens"
            return "[\(i)] \(c.habitType.rawValue) \(dir) \(c.metricName) by \(abs(Int(c.percentageChange)))% (n=\(c.sampleSize), confidence=\(c.confidenceLevel.rawValue))"
        }

        let prompt = """
        You are a health data analyst. Below are statistical correlations found from a user's personal health tracking data. \
        Some may be spurious or make no physiological sense (e.g., walking worsening HRV, or daily habits showing as negative when they are generally beneficial).

        CORRELATIONS:
        \(lines.joined(separator: "\n"))

        Return ONLY the bracket numbers of correlations that are physiologically plausible and meaningful, in order of most interesting/actionable first. \
        Remove any that are clearly nonsensical, spurious, or likely confounded. \
        Format: just comma-separated numbers, nothing else. Example: 0,2,4,1
        """

        guard let url = URL(string: "\(baseURL)/\(modelName):generateContent?key=\(apiKey)") else {
            return Array(correlations.indices)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "maxOutputTokens": 100,
                "temperature": 0.1
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return Array(correlations.indices)
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                return Array(correlations.indices)
            }

            // Parse comma-separated indices
            let indices = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: CharacterSet(charactersIn: ", \n"))
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                .filter { $0 >= 0 && $0 < correlations.count }

            print("InsightsSynthesizer: Gemini validated \(indices.count)/\(correlations.count) correlations")
            return indices.isEmpty ? Array(correlations.indices) : indices
        } catch {
            print("InsightsSynthesizer: Validation error: \(error.localizedDescription)")
            return Array(correlations.indices)
        }
    }

    // MARK: - Helpers

    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
