import Foundation
import SwiftUI

class StressScoreModel: ObservableObject {
    @Published var todayStressScore: Int?
    @Published var todayRecoveryScore: Int?
    @Published var last7DaysStress: [Int?] = []      // nil = no data for that day (watch not worn)
    @Published var last7DaysRecovery: [Int?] = []     // nil = no data for that day
    @Published var weeklyAvgStress: Int?
    @Published var weeklyAvgRecovery: Int?
    @Published var zScores: MetricZScores?
    @Published var sleepDeficit: Double?
    @Published var hasTemperatureData: Bool = false
    @Published var computedWeights: ComputedWeights?
    @Published var baselineDayCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var dataQuality: StressRecoveryScore.DataQuality?
    @Published var insufficientDataReason: String?    // Human-readable reason when no score

    private let engine = StressScoreEngine.shared

    /// Per-session cache of fetched metrics keyed by startOfDay.
    /// Avoids redundant HealthKit queries when computeScores and computeLast7Days
    /// both need data for the same date (especially today).
    private var metricsCache: [Date: NightlyMetrics?] = [:]

    init() {
        baselineDayCount = engine.loadBaseline().dates.count
    }

    /// Clears the metrics cache — call on manual refresh so fresh HK data is fetched.
    func invalidateCache() {
        metricsCache.removeAll()
    }

    // MARK: - Compute Today's Score

    func computeScores(forDate date: Date) {
        isLoading = true
        // Invalidate cache on new computation so we get fresh data
        metricsCache.removeAll()

        // Remember whether we already had a score — avoids flashing
        // from filled card to empty card when refreshing.
        let hadExistingScore = todayStressScore != nil
            || last7DaysStress.compactMap({ $0 }).count > 0

        fetchNightlyMetricsCached(for: date) { [weak self] metrics in
            guard let self = self else { return }

            guard let metrics = metrics else {
                // No data at all — watch probably wasn't worn
                DispatchQueue.main.async {
                    // Only clear the card if this is the first load
                    if !hadExistingScore {
                        self.todayStressScore = nil
                        self.todayRecoveryScore = nil
                        self.zScores = nil
                        self.sleepDeficit = nil
                        self.dataQuality = .insufficient
                        self.insufficientDataReason = "No health data available for this date. Wear your Apple Watch to generate a score."
                    }
                    self.isLoading = false
                    self.computeLast7Days(currentDate: date)
                }
                return
            }

            // Stress only needs HRV + RHR; recovery also needs sleep
            if !metrics.hasSufficientDataForStress {
                DispatchQueue.main.async {
                    if !hadExistingScore {
                        self.todayStressScore = nil
                        self.todayRecoveryScore = nil
                        self.zScores = nil
                        self.sleepDeficit = nil
                        self.dataQuality = .insufficient
                        self.insufficientDataReason = self.explainInsufficientData(metrics)
                    }
                    self.isLoading = false
                    self.computeLast7Days(currentDate: date)
                }
                return
            }

            var baseline = self.engine.loadBaseline()

            // Compute stress score (relaxed gate: HRV + RHR only)
            guard let stressScore = self.engine.computeScore(metrics: metrics, baseline: baseline, requireSleep: false) else {
                DispatchQueue.main.async {
                    if !hadExistingScore {
                        self.todayStressScore = nil
                        self.todayRecoveryScore = nil
                        self.dataQuality = .insufficient
                        self.insufficientDataReason = "Insufficient data quality to compute a reliable score."
                    }
                    self.isLoading = false
                    self.computeLast7Days(currentDate: date)
                }
                return
            }

            // Recovery score requires sleep — compute separately if sleep data exists
            let recoveryScore: StressRecoveryScore?
            if metrics.hasSufficientDataForRecovery {
                recoveryScore = self.engine.computeScore(metrics: metrics, baseline: baseline, requireSleep: true)
            } else {
                recoveryScore = nil
            }

            // Only update baseline with full-quality nights (sleep + HRV + RHR)
            if metrics.hasSufficientDataForRecovery {
                self.engine.updateBaseline(&baseline, with: metrics)
                self.engine.saveBaseline(baseline)
            }

            DispatchQueue.main.async {
                self.todayStressScore = stressScore.stressScore
                // Recovery only shows if sleep data was present
                self.todayRecoveryScore = recoveryScore?.recoveryScore
                self.zScores = stressScore.zScores
                // Only show sleep deficit if sleep data exists
                self.sleepDeficit = metrics.hasSleepData ? stressScore.sleepDeficit : nil
                self.hasTemperatureData = stressScore.hasTemperatureData
                self.computedWeights = stressScore.computedWeights
                self.baselineDayCount = baseline.dates.count
                self.dataQuality = stressScore.dataQuality
                self.insufficientDataReason = nil
                self.isLoading = false
                self.computeLast7Days(currentDate: date)
            }
        }
    }

    // MARK: - 7-Day History

    func computeLast7Days(currentDate: Date) {
        let calendar = Calendar.current
        let group = DispatchGroup()
        var stressScoresByDate: [Date: Int] = [:]
        var recoveryScoresByDate: [Date: Int] = [:]
        let baseline = engine.loadBaseline()

        var dates: [Date] = []
        for i in 0..<7 {
            if let d = calendar.date(byAdding: .day, value: -i, to: calendar.startOfDay(for: currentDate)) {
                dates.append(d)
            }
        }
        dates.reverse()

        for date in dates {
            group.enter()
            fetchNightlyMetricsCached(for: date) { [weak self] metrics in
                guard let self = self else {
                    group.leave()
                    return
                }

                // Need at least HRV + RHR for a stress score
                guard let metrics = metrics, metrics.hasSufficientDataForStress else {
                    group.leave()
                    return
                }

                // Stress uses relaxed gate (no sleep required)
                let stressResult = self.engine.computeScore(metrics: metrics, baseline: baseline, requireSleep: false)
                // Recovery uses strict gate (sleep required)
                let recoveryResult = metrics.hasSufficientDataForRecovery
                    ? self.engine.computeScore(metrics: metrics, baseline: baseline, requireSleep: true)
                    : nil

                DispatchQueue.main.async {
                    if let s = stressResult {
                        stressScoresByDate[date] = s.stressScore
                    }
                    if let r = recoveryResult {
                        recoveryScoresByDate[date] = r.recoveryScore
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // Stress can show on days without sleep; recovery only on days with sleep
            self.last7DaysStress = dates.map { stressScoresByDate[$0] }
            self.last7DaysRecovery = dates.map { recoveryScoresByDate[$0] }

            // Weekly averages only count days with real scores
            let validStress = self.last7DaysStress.compactMap { $0 }
            let validRecovery = self.last7DaysRecovery.compactMap { $0 }

            self.weeklyAvgStress = validStress.isEmpty ? nil : validStress.reduce(0, +) / validStress.count
            self.weeklyAvgRecovery = validRecovery.isEmpty ? nil : validRecovery.reduce(0, +) / validRecovery.count
        }
    }

    // MARK: - Cached Metrics Fetch

    /// Returns cached metrics if available, otherwise fetches from HealthKit and caches the result.
    /// This prevents duplicate HealthKit queries when computeScores() and computeLast7Days()
    /// both need the same date's data (saves ~10 HK queries per refresh cycle).
    private func fetchNightlyMetricsCached(for date: Date, completion: @escaping (NightlyMetrics?) -> Void) {
        let key = Calendar.current.startOfDay(for: date)

        // Check cache first
        if let cached = metricsCache[key] {
            completion(cached)
            return
        }

        // Fetch from HealthKit, then cache
        fetchNightlyMetrics(for: date) { [weak self] metrics in
            self?.metricsCache[key] = metrics
            completion(metrics)
        }
    }

    // MARK: - Fetch All Metrics for a Date

    private func fetchNightlyMetrics(for date: Date, completion: @escaping (NightlyMetrics?) -> Void) {
        let group = DispatchGroup()
        let hk = HealthKitManager.shared

        var hrv: Double?
        var rhr: Double?
        var respRate: Double?
        var wristTemp: Double?
        var sleepDuration: Double?

        group.enter()
        hk.fetchHRVDuringSleepForDate(date) { value in
            if let value = value {
                hrv = value
                group.leave()
            } else {
                // Fallback: sleep data may not have synced yet, try any HRV for the day
                hk.fetchAvgHRVForDay(date: date) { fallbackValue in
                    hrv = fallbackValue
                    group.leave()
                }
            }
        }

        group.enter()
        hk.fetchRestingHeartRateForDay(date: date) { value in
            if let value = value {
                rhr = value
                group.leave()
            } else {
                // Fallback: RHR sample may not have been written yet.
                // Use the minimum heart rate for the day as a proxy.
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
                hk.fetchMinimumHeartRate(from: startOfDay, to: endOfDay) { minHR in
                    rhr = minHR
                    group.leave()
                }
            }
        }

        group.enter()
        hk.fetchRespiratoryRateDuringSleep(for: date) { value in
            respRate = value
            group.leave()
        }

        group.enter()
        hk.fetchSleepingWristTemperature(for: date) { value in
            wristTemp = value
            group.leave()
        }

        group.enter()
        hk.fetchTotalSleepForNight(date: date) { value in
            sleepDuration = value
            group.leave()
        }

        group.notify(queue: .main) {
            // If absolutely nothing came back, return nil immediately
            if hrv == nil && rhr == nil && sleepDuration == nil && respRate == nil && wristTemp == nil {
                completion(nil)
                return
            }

            // Return the metrics — hasSufficientData check happens upstream
            completion(NightlyMetrics(
                date: date,
                hrv: hrv,
                rhr: rhr,
                respRate: respRate,
                wristTemp: wristTemp,
                sleepDuration: sleepDuration
            ))
        }
    }

    // MARK: - Insufficient Data Explanation

    private func explainInsufficientData(_ metrics: NightlyMetrics) -> String {
        var missing: [String] = []
        var found: [String] = []

        if metrics.hrv == nil { missing.append("HRV") } else { found.append("HRV") }
        if metrics.rhr == nil { missing.append("Resting HR") } else { found.append("Resting HR") }

        if missing.isEmpty {
            return "Insufficient data to generate a reliable score."
        }

        let missingStr = "Missing: \(missing.joined(separator: ", "))"
        let foundStr = found.isEmpty ? "" : " (found: \(found.joined(separator: ", ")))"
        return "\(missingStr)\(foundStr). Try opening the Health app to sync your Apple Watch data."
    }

    // MARK: - Helpers

    func getLastSevenDays() -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"

        var days: [String] = []
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                days.insert(dateFormatter.string(from: date).uppercased(), at: 0)
            }
        }
        return days
    }

    static func stressColorForScore(_ value: Int) -> Color {
        switch value {
        case 0...33:   return .green
        case 34...50:  return .yellow
        case 51...66:  return .orange
        default:       return .red
        }
    }

    static func stressStatusLabel(_ score: Int) -> String {
        switch score {
        case 0...33:   return "Low"
        case 34...50:  return "Moderate"
        case 51...66:  return "Elevated"
        default:       return "High"
        }
    }

    static func stressGuidanceText(_ score: Int) -> String {
        switch score {
        case 0...33:   return "Body is well-recovered"
        case 34...50:  return "Some accumulated stress"
        case 51...66:  return "Consider lighter activity"
        default:       return "Prioritize rest today"
        }
    }
}
