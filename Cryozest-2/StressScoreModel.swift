import Foundation
import SwiftUI

class StressScoreModel: ObservableObject {
    @Published var todayStressScore: Int?
    @Published var todayRecoveryScore: Int?
    @Published var last7DaysStress: [Int] = []
    @Published var last7DaysRecovery: [Int] = []
    @Published var weeklyAvgStress: Int = 0
    @Published var weeklyAvgRecovery: Int = 0
    @Published var zScores: MetricZScores?
    @Published var sleepDeficit: Double?
    @Published var hasTemperatureData: Bool = false
    @Published var baselineDayCount: Int = 0
    @Published var isLoading: Bool = false

    private let engine = StressScoreEngine.shared

    init() {
        baselineDayCount = engine.loadBaseline().dates.count
    }

    // MARK: - Compute Today's Score

    func computeScores(forDate date: Date) {
        isLoading = true

        let group = DispatchGroup()
        let hk = HealthKitManager.shared

        var hrv: Double?
        var rhr: Double?
        var respRate: Double?
        var wristTemp: Double?
        var sleepDuration: Double?

        // Fan out all HealthKit queries in parallel
        group.enter()
        hk.fetchHRVDuringSleepForDate(date) { value in
            hrv = value
            group.leave()
        }

        group.enter()
        hk.fetchRestingHeartRateForDay(date: date) { value in
            rhr = value
            group.leave()
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

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // Need at least HRV or RHR to compute a meaningful score
            guard hrv != nil || rhr != nil else {
                self.isLoading = false
                self.todayStressScore = nil
                self.todayRecoveryScore = nil
                return
            }

            let metrics = NightlyMetrics(
                date: date,
                hrv: hrv,
                rhr: rhr,
                respRate: respRate,
                wristTemp: wristTemp,
                sleepDuration: sleepDuration
            )

            var baseline = self.engine.loadBaseline()
            let score = self.engine.computeScore(metrics: metrics, baseline: baseline)

            // Update baseline with tonight's data
            self.engine.updateBaseline(&baseline, with: metrics)
            self.engine.saveBaseline(baseline)

            // Publish results
            self.todayStressScore = score.stressScore
            self.todayRecoveryScore = score.recoveryScore
            self.zScores = score.zScores
            self.sleepDeficit = score.sleepDeficit
            self.hasTemperatureData = score.hasTemperatureData
            self.baselineDayCount = baseline.dates.count

            self.isLoading = false

            // Compute 7-day history after today's score is ready
            self.computeLast7Days(currentDate: date)
        }
    }

    // MARK: - 7-Day History

    func computeLast7Days(currentDate: Date) {
        let calendar = Calendar.current
        let group = DispatchGroup()
        var scoresByDate: [Date: StressRecoveryScore] = [:]
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
            fetchNightlyMetrics(for: date) { [weak self] metrics in
                guard let self = self, let metrics = metrics else {
                    group.leave()
                    return
                }

                let score = self.engine.computeScore(metrics: metrics, baseline: baseline)
                DispatchQueue.main.async {
                    scoresByDate[date] = score
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            self.last7DaysStress = dates.map { scoresByDate[$0]?.stressScore ?? 0 }
            self.last7DaysRecovery = dates.map { scoresByDate[$0]?.recoveryScore ?? 0 }

            let validStress = self.last7DaysStress.filter { $0 > 0 }
            let validRecovery = self.last7DaysRecovery.filter { $0 > 0 }

            self.weeklyAvgStress = validStress.isEmpty ? 0 : validStress.reduce(0, +) / validStress.count
            self.weeklyAvgRecovery = validRecovery.isEmpty ? 0 : validRecovery.reduce(0, +) / validRecovery.count
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
            hrv = value
            group.leave()
        }

        group.enter()
        hk.fetchRestingHeartRateForDay(date: date) { value in
            rhr = value
            group.leave()
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
            // Need at least one core metric
            guard hrv != nil || rhr != nil else {
                completion(nil)
                return
            }

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
