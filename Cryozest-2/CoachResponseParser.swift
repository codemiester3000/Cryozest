import SwiftUI

// MARK: - Response Block Models

struct CoachResponseBlock: Identifiable {
    let id = UUID()
    let content: BlockContent

    enum BlockContent {
        case text(String)
        case metric(MetricData)
        case metricsRow([MetricData])
        case chart(ChartBlockData)
        case comparison(ComparisonData)
        case tip(TipData)
        case workoutSummary(WorkoutSummaryData)
        case sessionList(SessionListData)
        case heartZones(HeartZoneData)
    }
}

struct WorkoutSummaryData {
    let type: String
    let date: String
    let durationMinutes: Int
    let avgHeartRate: Int?
    let isAppleWatch: Bool
}

struct SessionListData {
    let title: String
    let sessions: [SessionSnapshot]
}

struct HeartZoneData {
    let recovery: Int      // minutes
    let conditioning: Int
    let overload: Int
}

struct MetricData: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let unit: String
    let trend: CoachTrend
    let change: String?
}

enum CoachTrend: String {
    case up, down, stable

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .orange
        case .stable: return .white.opacity(0.5)
        }
    }
}

struct ChartBlockData {
    let title: String
    let values: [ChartPoint]
    let unit: String
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct ComparisonData {
    let title: String
    let items: [ComparisonItem]
}

struct ComparisonItem: Identifiable {
    let id = UUID()
    let label: String
    let current: String
    let previous: String
    let trend: CoachTrend
}

struct TipData {
    let text: String
    let icon: String
}

// MARK: - Health Snapshot

struct SessionSnapshot {
    let type: String           // display name
    let date: Date
    let durationMinutes: Int
    let avgHeartRate: Int?     // nil if manual/no HR
    let isAppleWatch: Bool
}

struct WorkoutVolume {
    let type: String
    let sessionCount: Int
    let totalMinutes: Int
    let avgHeartRate: Int?
}

struct HealthSnapshot {
    // Recovery
    var recoveryScore: Int?
    var recoveryScores: [Int] = []  // last 7 days
    var weeklyAverage: Int?

    // HRV
    var hrv: Int?
    var hrvBaseline: Int?

    // Heart Rate
    var rhr: Int?
    var rhrBaseline: Int?

    // Sleep
    var sleepDuration: String?
    var sleepScore: Int?
    var deepSleep: String?
    var remSleep: String?
    var coreSleep: String?
    var restorativePercent: Int?

    // Other vitals
    var spo2: Double?
    var vo2Max: Double?
    var steps: Int?
    var activeCalories: Int?
    var respiratoryRate: Double?

    // Sleep heart rates
    var sleepHeartRate: Int?
    var wakingHeartRate: Int?

    // Exertion
    var exertionScore: Int?

    // All therapy type names the user tracks (for dynamic sport matching)
    var trackedHabitNames: [String] = []

    // Trends (week-over-week)
    var healthTrends: [(metric: String, change: Int, isPositive: Bool)] = []

    // Workout sessions
    var recentSessions: [SessionSnapshot] = []
    var weeklyVolume: [WorkoutVolume] = []

    // Wellness
    var mood: Int?              // today's most recent (1-5)
    var moodHistory: [Int] = [] // last 7 daily averages
    var pain: Int?              // today's most recent (0-5)
    var painLocation: String?
    var painHistory: [Int] = [] // last 7 daily averages
    var waterCups: Int?
    var waterGoal: Int = 8

    // Exertion zones
    var recoveryMinutes: Int?
    var conditioningMinutes: Int?
    var overloadMinutes: Int?
}

// MARK: - Parser

struct CoachResponseParser {

    /// Parse a natural language Gemini response into rich blocks by scanning for
    /// metric keywords and injecting client-side widgets from the health snapshot.
    static func parse(_ response: String, snapshot: HealthSnapshot) -> [CoachResponseBlock] {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Split into paragraphs
        let paragraphs = trimmed
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var blocks: [CoachResponseBlock] = []
        var injectedWidgets: Set<String> = []
        var widgetCount = 0
        let maxWidgets = 5

        // Build dynamic sport keywords from user's tracked habits + common aliases
        var sportKeywords: [(keywords: [String], type: String?)] = [
            (["workout", "session", "training", "exercise", "activity"], nil),
        ]
        // Static well-known aliases
        let sportAliases: [(aliases: [String], matchType: String)] = [
            (["swim", "swimming", "pool", "lap"], "swim"),
            (["run", "running", "jog", "jogging"], "run"),
            (["lift", "weight", "strength", "gym", "bench", "squat", "deadlift"], "weight"),
            (["cycling", "bike", "biking", "ride", "spin"], "cycl"),
            (["yoga", "stretch"], "yoga"),
            (["meditation", "meditat", "mindful"], "meditat"),
            (["sauna", "steam", "heat"], "sauna"),
            (["cold plunge", "ice bath", "cryotherapy", "cold exposure", "cold water"], "cold"),
            (["hike", "hiking", "trek"], "hik"),
            (["walk", "walking"], "walk"),
            (["pilates"], "pilates"),
            (["boxing", "martial art", "mma", "kickbox"], "box"),
            (["rowing", "row"], "row"),
            (["surf", "surfing"], "surf"),
        ]
        for alias in sportAliases {
            sportKeywords.insert((alias.aliases, alias.matchType), at: sportKeywords.count - 1)
        }
        // Also add each user-tracked habit name as a keyword pointing to itself
        for name in snapshot.trackedHabitNames {
            let lowerName = name.lowercased()
            // Skip if already covered by static aliases
            let alreadyCovered = sportAliases.contains { pair in
                pair.aliases.contains { lowerName.contains($0) } ||
                lowerName.contains(pair.matchType)
            }
            if !alreadyCovered {
                sportKeywords.insert(([lowerName], lowerName), at: sportKeywords.count - 1)
            }
        }

        for paragraph in paragraphs {
            // Extract tips from the paragraph; remaining text becomes a text block
            let (textPart, tips) = extractTips(from: paragraph)

            if !textPart.isEmpty {
                let cleaned = cleanMarkdown(textPart)
                blocks.append(CoachResponseBlock(content: .text(cleaned)))
            }

            // Inject widgets based on keyword scanning (capped)
            guard widgetCount < maxWidgets else { continue }
            let lower = paragraph.lowercased()

            // --- Priority 1: Sport/workout mentions → session list ---
            if !injectedWidgets.contains("sessions"), widgetCount < maxWidgets {
                let matchedSport = sportKeywords.first { pair in
                    pair.keywords.contains { lower.contains($0) }
                }

                if let match = matchedSport, !snapshot.recentSessions.isEmpty {
                    let filtered: [SessionSnapshot]
                    let title: String

                    if let matchType = match.type {
                        filtered = snapshot.recentSessions.filter {
                            $0.type.lowercased().contains(matchType)
                        }
                        title = filtered.first.map { "Recent \($0.type) Sessions" } ?? "Recent Sessions"
                    } else {
                        // Generic workout/session/training → show all
                        filtered = Array(snapshot.recentSessions.prefix(5))
                        title = "Recent Sessions"
                    }

                    if !filtered.isEmpty {
                        injectedWidgets.insert("sessions")
                        blocks.append(CoachResponseBlock(content: .sessionList(
                            SessionListData(title: title, sessions: Array(filtered.prefix(5)))
                        )))
                        widgetCount += 1
                    }
                }
            }

            // --- Priority 2: Mood ---
            if !injectedWidgets.contains("mood"),
               lower.containsAny(["mood", "feeling", "wellness check", "how am i doing", "mental"]),
               let mood = snapshot.mood, widgetCount < maxWidgets {
                injectedWidgets.insert("mood")
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "Mood", value: "\(mood)", unit: "/5", trend: .stable, change: nil)
                )))
                widgetCount += 1

                if widgetCount < maxWidgets, snapshot.moodHistory.count >= 3 {
                    let dayLabels = lastNDayLabels(snapshot.moodHistory.count)
                    let points = zip(dayLabels, snapshot.moodHistory).map {
                        ChartPoint(label: $0, value: Double($1))
                    }
                    blocks.append(CoachResponseBlock(content: .chart(
                        ChartBlockData(title: "Mood (7 days)", values: points, unit: "/5")
                    )))
                    widgetCount += 1
                }
            }

            // --- Priority 3: Pain ---
            if !injectedWidgets.contains("pain"),
               lower.containsAny(["pain", "soreness", "hurt", "ache", "sore", "injury"]),
               let pain = snapshot.pain, widgetCount < maxWidgets {
                injectedWidgets.insert("pain")
                let locationStr = snapshot.painLocation.map { " (\($0))" } ?? ""
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "Pain\(locationStr)", value: "\(pain)", unit: "/5", trend: .stable, change: nil)
                )))
                widgetCount += 1

                if widgetCount < maxWidgets, snapshot.painHistory.count >= 3 {
                    let dayLabels = lastNDayLabels(snapshot.painHistory.count)
                    let points = zip(dayLabels, snapshot.painHistory).map {
                        ChartPoint(label: $0, value: Double($1))
                    }
                    blocks.append(CoachResponseBlock(content: .chart(
                        ChartBlockData(title: "Pain (7 days)", values: points, unit: "/5")
                    )))
                    widgetCount += 1
                }
            }

            // --- Priority 4: Water/Hydration ---
            if !injectedWidgets.contains("water"),
               lower.containsAny(["water", "hydration", "hydrate", "drink"]),
               let cups = snapshot.waterCups, widgetCount < maxWidgets {
                injectedWidgets.insert("water")
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "Water", value: "\(cups)/\(snapshot.waterGoal)", unit: "cups", trend: .stable, change: nil)
                )))
                widgetCount += 1
            }

            // --- Priority 5: Heart zones ---
            if !injectedWidgets.contains("zones"),
               lower.containsAny(["zones", "intensity", "exertion breakdown", "heart zone"]),
               widgetCount < maxWidgets,
               let recMin = snapshot.recoveryMinutes,
               let condMin = snapshot.conditioningMinutes,
               let ovlMin = snapshot.overloadMinutes,
               (recMin + condMin + ovlMin) > 0 {
                injectedWidgets.insert("zones")
                blocks.append(CoachResponseBlock(content: .heartZones(
                    HeartZoneData(recovery: recMin, conditioning: condMin, overload: ovlMin)
                )))
                widgetCount += 1
            }

            // --- Recovery (broader keyword match) ---
            if !injectedWidgets.contains("recovery"),
               lower.containsAny(["recovery"]),
               let score = snapshot.recoveryScore, widgetCount < maxWidgets {
                injectedWidgets.insert("recovery")

                let trend = trendForRecovery(score, average: snapshot.weeklyAverage)
                let change = snapshot.weeklyAverage.map { "avg \($0)%" }
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "Recovery", value: "\(score)", unit: "%", trend: trend, change: change)
                )))
                widgetCount += 1

                if widgetCount < maxWidgets, snapshot.recoveryScores.count >= 3 {
                    let dayLabels = lastNDayLabels(snapshot.recoveryScores.count)
                    let points = zip(dayLabels, snapshot.recoveryScores).map {
                        ChartPoint(label: $0, value: Double($1))
                    }
                    blocks.append(CoachResponseBlock(content: .chart(
                        ChartBlockData(title: "Recovery Trend", values: points, unit: "%")
                    )))
                    widgetCount += 1
                }
            }

            // --- HRV ---
            if !injectedWidgets.contains("hrv"),
               lower.containsAny(["hrv", "heart rate variability"]),
               let hrv = snapshot.hrv, widgetCount < maxWidgets {
                injectedWidgets.insert("hrv")

                let trend = trendVsBaseline(current: hrv, baseline: snapshot.hrvBaseline, higherIsGood: true)
                let change = snapshot.hrvBaseline.map { "baseline \($0) ms" }
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "HRV", value: "\(hrv)", unit: "ms", trend: trend, change: change)
                )))
                widgetCount += 1
            }

            // --- Resting Heart Rate (specific "resting heart rate"/"rhr", NOT generic "heart rate") ---
            if !injectedWidgets.contains("rhr"),
               lower.containsAny(["resting heart rate", "rhr"]),
               let rhr = snapshot.rhr, widgetCount < maxWidgets {
                injectedWidgets.insert("rhr")

                let trend = trendVsBaseline(current: rhr, baseline: snapshot.rhrBaseline, higherIsGood: false)
                let change = snapshot.rhrBaseline.map { "baseline \($0) bpm" }
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "Resting HR", value: "\(rhr)", unit: "bpm", trend: trend, change: change)
                )))
                widgetCount += 1
            }

            // --- Generic "heart rate" (not resting, not HRV) → show sleep/waking HR or sessions with HR ---
            if !injectedWidgets.contains("rhr"),
               !injectedWidgets.contains("sessions"),
               lower.contains("heart rate") && !lower.containsAny(["resting", "rhr", "variability", "hrv"]),
               widgetCount < maxWidgets {
                // If we have workout sessions with HR data, show those
                let sessionsWithHR = snapshot.recentSessions.filter { $0.avgHeartRate != nil }
                if !sessionsWithHR.isEmpty {
                    injectedWidgets.insert("sessions")
                    blocks.append(CoachResponseBlock(content: .sessionList(
                        SessionListData(title: "Workout Heart Rates", sessions: Array(sessionsWithHR.prefix(5)))
                    )))
                    widgetCount += 1
                } else if let sleepHR = snapshot.sleepHeartRate, let wakingHR = snapshot.wakingHeartRate {
                    // Fall back to sleep/waking HR comparison
                    injectedWidgets.insert("rhr")
                    let metrics = [
                        MetricData(label: "Sleep HR", value: "\(sleepHR)", unit: "bpm", trend: .stable, change: nil),
                        MetricData(label: "Waking HR", value: "\(wakingHR)", unit: "bpm", trend: .stable, change: nil),
                    ]
                    blocks.append(CoachResponseBlock(content: .metricsRow(metrics)))
                    widgetCount += 1
                }
            }

            // --- Sleep ---
            if !injectedWidgets.contains("sleep"),
               lower.containsAny(["sleep", "slept", "bedtime", "rest quality"]),
               widgetCount < maxWidgets {
                injectedWidgets.insert("sleep")

                // Primary: sleep duration + score as one metric
                if let duration = snapshot.sleepDuration, duration != "--" {
                    let scoreStr = snapshot.sleepScore.map { " (\($0)/100)" } ?? ""
                    blocks.append(CoachResponseBlock(content: .metric(
                        MetricData(label: "Sleep", value: duration, unit: "hrs" + scoreStr, trend: .stable, change: nil)
                    )))
                    widgetCount += 1
                }

                // Sleep stages as compact row
                if widgetCount < maxWidgets {
                    var stageMetrics: [MetricData] = []
                    if let deep = snapshot.deepSleep, deep != "--" {
                        stageMetrics.append(MetricData(label: "Deep", value: deep, unit: "", trend: .stable, change: nil))
                    }
                    if let rem = snapshot.remSleep, rem != "--" {
                        stageMetrics.append(MetricData(label: "REM", value: rem, unit: "", trend: .stable, change: nil))
                    }
                    if let core = snapshot.coreSleep, core != "--" {
                        stageMetrics.append(MetricData(label: "Core", value: core, unit: "", trend: .stable, change: nil))
                    }
                    if stageMetrics.count >= 2 {
                        blocks.append(CoachResponseBlock(content: .metricsRow(stageMetrics)))
                        widgetCount += 1
                    }
                }
            }

            // --- Steps ---
            if !injectedWidgets.contains("steps"),
               lower.containsAny(["steps", "step count", "walking"]),
               let steps = snapshot.steps, widgetCount < maxWidgets {
                injectedWidgets.insert("steps")
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "Steps", value: "\(steps)", unit: "", trend: .stable, change: nil)
                )))
                widgetCount += 1
            }

            // --- Calories ---
            if !injectedWidgets.contains("calories"),
               lower.containsAny(["calories", "active calories", "calorie", "energy burn"]),
               let cal = snapshot.activeCalories, widgetCount < maxWidgets {
                injectedWidgets.insert("calories")
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "Active Calories", value: "\(cal)", unit: "kcal", trend: .stable, change: nil)
                )))
                widgetCount += 1
            }

            // --- SpO2 ---
            if !injectedWidgets.contains("spo2"),
               lower.containsAny(["spo2", "oxygen saturation", "blood oxygen"]),
               let spo2 = snapshot.spo2, widgetCount < maxWidgets {
                injectedWidgets.insert("spo2")
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "SpO2", value: String(format: "%.1f", spo2), unit: "%", trend: .stable, change: nil)
                )))
                widgetCount += 1
            }

            // --- VO2 Max ---
            if !injectedWidgets.contains("vo2"),
               lower.containsAny(["vo2", "vo2 max", "cardio fitness"]),
               let vo2 = snapshot.vo2Max, widgetCount < maxWidgets {
                injectedWidgets.insert("vo2")
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "VO2 Max", value: String(format: "%.1f", vo2), unit: "mL/kg/min", trend: .stable, change: nil)
                )))
                widgetCount += 1
            }

            // --- Respiratory Rate ---
            if !injectedWidgets.contains("resprate"),
               lower.containsAny(["respiratory", "breathing rate", "breaths"]),
               let rr = snapshot.respiratoryRate, widgetCount < maxWidgets {
                injectedWidgets.insert("resprate")
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "Respiratory Rate", value: String(format: "%.1f", rr), unit: "br/min", trend: .stable, change: nil)
                )))
                widgetCount += 1
            }

            // --- Exertion ---
            if !injectedWidgets.contains("exertion"),
               lower.containsAny(["exertion", "strain"]),
               let exertion = snapshot.exertionScore, widgetCount < maxWidgets {
                injectedWidgets.insert("exertion")
                blocks.append(CoachResponseBlock(content: .metric(
                    MetricData(label: "Exertion", value: "\(exertion)", unit: "", trend: .stable, change: nil)
                )))
                widgetCount += 1

                // Also show zone breakdown if available
                if !injectedWidgets.contains("zones"),
                   widgetCount < maxWidgets,
                   let recMin = snapshot.recoveryMinutes,
                   let condMin = snapshot.conditioningMinutes,
                   let ovlMin = snapshot.overloadMinutes,
                   (recMin + condMin + ovlMin) > 0 {
                    injectedWidgets.insert("zones")
                    blocks.append(CoachResponseBlock(content: .heartZones(
                        HeartZoneData(recovery: recMin, conditioning: condMin, overload: ovlMin)
                    )))
                    widgetCount += 1
                }
            }

            // --- Trends / comparisons ---
            if !injectedWidgets.contains("trends"),
               lower.containsAny(["compared to", "vs last week", "trending", "week over week", "trend"]),
               !snapshot.healthTrends.isEmpty, widgetCount < maxWidgets {
                injectedWidgets.insert("trends")
                let items = snapshot.healthTrends.prefix(4).map { trend in
                    ComparisonItem(
                        label: trend.metric,
                        current: "\(trend.change > 0 ? "+" : "")\(trend.change)%",
                        previous: "last week",
                        trend: trend.isPositive ? .up : .down
                    )
                }
                blocks.append(CoachResponseBlock(content: .comparison(
                    ComparisonData(title: "Week over Week", items: items)
                )))
                widgetCount += 1
            }

            // --- Health overview / full breakdown — inject a multi-metric summary ---
            if !injectedWidgets.contains("overview"),
               lower.containsAny(["breakdown", "overview", "full health", "summary", "how am i", "overall"]),
               widgetCount < maxWidgets {
                injectedWidgets.insert("overview")
                var overviewMetrics: [MetricData] = []

                if let score = snapshot.recoveryScore {
                    let trend = trendForRecovery(score, average: snapshot.weeklyAverage)
                    overviewMetrics.append(MetricData(label: "Recovery", value: "\(score)", unit: "%", trend: trend, change: nil))
                }
                if let hrv = snapshot.hrv {
                    let trend = trendVsBaseline(current: hrv, baseline: snapshot.hrvBaseline, higherIsGood: true)
                    overviewMetrics.append(MetricData(label: "HRV", value: "\(hrv)", unit: "ms", trend: trend, change: nil))
                }
                if let rhr = snapshot.rhr {
                    let trend = trendVsBaseline(current: rhr, baseline: snapshot.rhrBaseline, higherIsGood: false)
                    overviewMetrics.append(MetricData(label: "RHR", value: "\(rhr)", unit: "bpm", trend: trend, change: nil))
                }
                if let score = snapshot.sleepScore {
                    overviewMetrics.append(MetricData(label: "Sleep", value: "\(score)", unit: "/100", trend: .stable, change: nil))
                }

                if overviewMetrics.count >= 2 {
                    blocks.append(CoachResponseBlock(content: .metricsRow(Array(overviewMetrics.prefix(4)))))
                    widgetCount += 1
                }
            }

            // Tips extracted from the paragraph
            for tip in tips where widgetCount < maxWidgets {
                blocks.append(CoachResponseBlock(content: .tip(TipData(text: tip, icon: tipIcon(for: tip)))))
                widgetCount += 1
            }
        }

        // If we produced nothing, return the full response as text
        if blocks.isEmpty {
            return [CoachResponseBlock(content: .text(cleanMarkdown(trimmed)))]
        }

        return blocks
    }

    /// Extract just the human-readable text from blocks, for conversation history.
    static func extractPlainText(from blocks: [CoachResponseBlock]) -> String {
        blocks.compactMap { block -> String? in
            switch block.content {
            case .text(let text):
                return text
            case .metric(let data):
                var result = "\(data.label): \(data.value) \(data.unit)"
                if let change = data.change { result += " (\(change))" }
                return result
            case .metricsRow(let metrics):
                return metrics.map { "\($0.label): \($0.value) \($0.unit)" }.joined(separator: ", ")
            case .chart(let data):
                return "\(data.title): " + data.values.map { "\($0.label) \($0.value)\(data.unit)" }.joined(separator: ", ")
            case .comparison(let data):
                let items = data.items.map { "\($0.label): \($0.previous) → \($0.current)" }.joined(separator: ", ")
                return "\(data.title): \(items)"
            case .tip(let data):
                return "Tip: \(data.text)"
            case .workoutSummary(let data):
                var result = "\(data.type): \(data.date), \(data.durationMinutes) min"
                if let hr = data.avgHeartRate { result += ", avg HR \(hr) bpm" }
                return result
            case .sessionList(let data):
                let lines = data.sessions.map { s in
                    var line = "\(s.type): \(s.durationMinutes) min"
                    if let hr = s.avgHeartRate { line += ", HR \(hr)" }
                    return line
                }
                return "\(data.title): " + lines.joined(separator: "; ")
            case .heartZones(let data):
                return "Heart Zones — Recovery: \(data.recovery) min, Conditioning: \(data.conditioning) min, Overload: \(data.overload) min"
            }
        }.joined(separator: "\n")
    }

    // MARK: - Follow-Up Extraction

    static func extractFollowUps(_ response: String) -> (cleaned: String, followUps: [String]) {
        var followUps: [String] = []
        let pattern = #"\[FOLLOWUP:\s*(.+?)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (response, [])
        }

        let matches = regex.matches(in: response, range: NSRange(response.startIndex..., in: response))
        for match in matches {
            if let range = Range(match.range(at: 1), in: response) {
                let text = String(response[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    followUps.append(text)
                }
            }
        }

        let cleaned = regex.stringByReplacingMatches(
            in: response,
            range: NSRange(response.startIndex..., in: response),
            withTemplate: ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        return (cleaned, Array(followUps.prefix(3)))
    }

    // MARK: - Tip Extraction

    /// Splits a paragraph into (remaining text, extracted tips).
    /// Sentences starting with actionable phrases become tip blocks.
    private static func extractTips(from paragraph: String) -> (String, [String]) {
        let tipPrefixes = [
            "try ", "consider ", "i'd recommend ", "i recommend ", "aim for ",
            "make sure ", "focus on ", "prioritize ", "start with ", "avoid ",
            "💡 ", "tip: ", "suggestion: "
        ]

        // Split into sentences
        let sentences = paragraph.splitIntoSentences()
        var textParts: [String] = []
        var tips: [String] = []

        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()

            if tipPrefixes.contains(where: { lower.hasPrefix($0) }) {
                // Clean up the tip text
                var tipText = trimmed
                if tipText.hasPrefix("💡 ") { tipText = String(tipText.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
                if lower.hasPrefix("tip: ") { tipText = String(tipText.dropFirst(5)) }
                if lower.hasPrefix("suggestion: ") { tipText = String(tipText.dropFirst(12)) }
                tips.append(tipText)
            } else {
                textParts.append(trimmed)
            }
        }

        let text = textParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return (text, tips)
    }

    // MARK: - Helpers

    private static func cleanMarkdown(_ text: String) -> String {
        var result = text
        // Remove bold markers **text** → text
        result = result.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression)
        // Remove italic markers *text* → text
        result = result.replacingOccurrences(of: "\\*(.+?)\\*", with: "$1", options: .regularExpression)
        return result
    }

    private static func trendForRecovery(_ score: Int, average: Int?) -> CoachTrend {
        guard let avg = average else { return .stable }
        if score > avg + 3 { return .up }
        if score < avg - 3 { return .down }
        return .stable
    }

    private static func trendVsBaseline(current: Int, baseline: Int?, higherIsGood: Bool) -> CoachTrend {
        guard let base = baseline else { return .stable }
        let diff = current - base
        if abs(diff) <= 2 { return .stable }
        let isHigher = diff > 0
        return (isHigher == higherIsGood) ? .up : .down
    }

    private static func lastNDayLabels(_ n: Int) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let calendar = Calendar.current
        return (0..<n).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return formatter.string(from: date)
        }
    }

    private static func tipIcon(for text: String) -> String {
        let lower = text.lowercased()
        if lower.containsAny(["sleep", "bed", "rest", "nap"]) { return "moon" }
        if lower.containsAny(["walk", "step", "move", "exercise", "workout"]) { return "figure.walk" }
        if lower.containsAny(["heart", "cardio"]) { return "heart" }
        if lower.containsAny(["water", "hydrat", "drink"]) { return "drop" }
        if lower.containsAny(["stress", "relax", "breath", "meditat"]) { return "brain" }
        if lower.containsAny(["energy", "fuel", "calorie"]) { return "flame" }
        return "lightbulb"
    }
}

// MARK: - String Helpers

private extension Array where Element == String {
    func containsAny(_ keywords: [String]) -> Bool {
        for keyword in keywords {
            if self.contains(where: { $0.lowercased().contains(keyword.lowercased()) }) {
                return true
            }
        }
        return false
    }
}

private extension String {
    func containsAny(_ keywords: [String]) -> Bool {
        let lower = self.lowercased()
        return keywords.contains { lower.contains($0) }
    }

    /// Rough sentence splitting that handles common abbreviations.
    func splitIntoSentences() -> [String] {
        var sentences: [String] = []
        var current = ""

        for char in self {
            current.append(char)
            if char == "." || char == "!" || char == "?" {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 5 { // skip very short fragments like "Dr."
                    sentences.append(trimmed)
                    current = ""
                }
            }
        }
        let remaining = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !remaining.isEmpty {
            sentences.append(remaining)
        }
        return sentences
    }
}
