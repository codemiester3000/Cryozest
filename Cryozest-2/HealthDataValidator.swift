import Foundation

struct HealthDataValidator {
    static func isValidSleepDuration(_ hours: Double) -> Bool {
        hours >= 1.0 && hours <= 24.0
    }

    static func isValidHRV(_ ms: Int) -> Bool {
        ms >= 5 && ms <= 250
    }

    static func isValidRestingHR(_ bpm: Int) -> Bool {
        bpm >= 30 && bpm <= 120
    }

    static func isValidSpO2(_ pct: Double) -> Bool {
        pct >= 85.0 && pct <= 100.0
    }

    static func isValidSteps(_ count: Int) -> Bool {
        count > 0 && count <= 100_000
    }

    static func isValidDisplayString(_ str: String?) -> Bool {
        guard let str = str else { return false }
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        let invalid = ["--", "N/A", "n/a", "0.0", "0", "0.00"]
        return !invalid.contains(trimmed)
    }
}
