import Foundation

// MARK: - Data Structures

struct NightlyMetrics {
    let date: Date
    let hrv: Double?           // SDNN tonight (ms)
    let rhr: Double?           // Resting heart rate tonight (bpm)
    let respRate: Double?      // Respiratory rate during sleep (br/min)
    let wristTemp: Double?     // Wrist temp deviation (°C), nil if unavailable
    let sleepDuration: Double? // Total sleep in seconds
}

struct StressRecoveryScore {
    let date: Date
    let stressScore: Int       // 0-100, higher = more stressed
    let recoveryScore: Int     // 0-100, higher = more recovered
    let stressRaw: Double      // Raw stress value before scaling
    let zScores: MetricZScores
    let sleepDeficit: Double
    let hasTemperatureData: Bool
}

struct MetricZScores {
    let hrv: Double?
    let rhr: Double?
    let respRate: Double?
    let wristTemp: Double?
}

struct BaselineData: Codable {
    var hrvValues: [Double]        // last 14 nightly SDNN values
    var rhrValues: [Double]        // last 14 nightly RHR values
    var respRateValues: [Double]   // last 14 nightly resp rate values
    var wristTempValues: [Double]  // last 14 nightly temp deviations
    var sleepDurations: [Double]   // last 14 nightly sleep durations (seconds)
    var dates: [Date]              // corresponding dates

    static var empty: BaselineData {
        BaselineData(
            hrvValues: [],
            rhrValues: [],
            respRateValues: [],
            wristTempValues: [],
            sleepDurations: [],
            dates: []
        )
    }
}

// MARK: - Population Priors (Cold Start)

struct PopulationPrior {
    let mean: Double
    let stdev: Double
}

// MARK: - Engine

class StressScoreEngine {
    static let shared = StressScoreEngine()

    // Population priors for cold start (first 14 days)
    private let hrvPrior = PopulationPrior(mean: 40.0, stdev: 20.0)
    private let rhrPrior = PopulationPrior(mean: 62.0, stdev: 8.0)
    private let respRatePrior = PopulationPrior(mean: 15.0, stdev: 2.0)
    private let wristTempPrior = PopulationPrior(mean: 0.0, stdev: 0.3)
    private let sleepDurationPrior = PopulationPrior(mean: 25200.0, stdev: 3600.0) // 7 hours in seconds

    // Weights
    private let weightHRV: Double = -0.35
    private let weightRHR: Double = 0.25
    private let weightResp: Double = 0.15
    private let weightTemp: Double = 0.10
    private let weightSleep: Double = 0.15

    // Weights when temperature is unavailable (redistributed)
    private let weightRHR_noTemp: Double = 0.30
    private let weightResp_noTemp: Double = 0.20

    // Scaling factor: ±3 stdev maps to full 0-100 range
    private let scalingFactor: Double = 16.67

    private let baselineKey = "stressScoreBaseline"
    private let scoresKey = "stressScoreHistory"

    private init() {}

    // MARK: - Score Computation

    func computeScore(metrics: NightlyMetrics, baseline: BaselineData) -> StressRecoveryScore {
        let dayCount = baseline.dates.count
        let hasTemp = metrics.wristTemp != nil

        // Compute Z-scores
        let zHRV = computeZScore(
            value: metrics.hrv,
            personalValues: baseline.hrvValues,
            prior: hrvPrior,
            dayCount: dayCount
        )

        let zRHR = computeZScore(
            value: metrics.rhr,
            personalValues: baseline.rhrValues,
            prior: rhrPrior,
            dayCount: dayCount
        )

        let zResp = computeZScore(
            value: metrics.respRate,
            personalValues: baseline.respRateValues,
            prior: respRatePrior,
            dayCount: dayCount
        )

        let zTemp: Double? = hasTemp ? computeZScore(
            value: metrics.wristTemp,
            personalValues: baseline.wristTempValues,
            prior: wristTempPrior,
            dayCount: dayCount
        ) : nil

        // Sleep deficit
        let sleepDeficit = computeSleepDeficit(
            sleepTonight: metrics.sleepDuration,
            personalSleepValues: baseline.sleepDurations,
            prior: sleepDurationPrior,
            dayCount: dayCount
        )

        // Combine into raw stress score
        var stressRaw: Double = 0.0

        if hasTemp, let zT = zTemp {
            // Full formula with temperature
            stressRaw = (weightHRV * (zHRV ?? 0.0))
                      + (weightRHR * (zRHR ?? 0.0))
                      + (weightResp * (zResp ?? 0.0))
                      + (weightTemp * zT)
                      + (weightSleep * sleepDeficit)
        } else {
            // Redistributed weights without temperature
            stressRaw = (weightHRV * (zHRV ?? 0.0))
                      + (weightRHR_noTemp * (zRHR ?? 0.0))
                      + (weightResp_noTemp * (zResp ?? 0.0))
                      + (weightSleep * sleepDeficit)
        }

        // Scale to 0-100
        let recoveryRaw = 50.0 - (stressRaw * scalingFactor)
        let stressScaled = 50.0 + (stressRaw * scalingFactor)

        let recoveryScore = Int(min(max(recoveryRaw, 0), 100).rounded())
        let stressScore = Int(min(max(stressScaled, 0), 100).rounded())

        return StressRecoveryScore(
            date: metrics.date,
            stressScore: stressScore,
            recoveryScore: recoveryScore,
            stressRaw: stressRaw,
            zScores: MetricZScores(hrv: zHRV, rhr: zRHR, respRate: zResp, wristTemp: zTemp),
            sleepDeficit: sleepDeficit,
            hasTemperatureData: hasTemp
        )
    }

    // MARK: - Z-Score Computation

    private func computeZScore(value: Double?, personalValues: [Double], prior: PopulationPrior, dayCount: Int) -> Double? {
        guard let value = value else { return nil }

        let (mean, stdev) = blendedMeanAndStdev(
            personalValues: personalValues,
            prior: prior,
            dayCount: dayCount
        )

        // Avoid division by zero
        guard stdev > 0 else { return 0.0 }

        return (value - mean) / stdev
    }

    // MARK: - Cold Start Blending

    private func blendedMeanAndStdev(personalValues: [Double], prior: PopulationPrior, dayCount: Int) -> (mean: Double, stdev: Double) {
        let effectiveDayCount = min(dayCount, 14)

        if personalValues.isEmpty {
            return (prior.mean, prior.stdev)
        }

        let personalMean = personalValues.reduce(0, +) / Double(personalValues.count)
        let personalStdev = standardDeviation(personalValues)

        if effectiveDayCount >= 14 {
            // Fully personal baseline
            return (personalMean, max(personalStdev, 0.001))
        }

        // Blend: linear interpolation between population prior and personal
        let personalWeight = Double(effectiveDayCount) / 14.0
        let priorWeight = 1.0 - personalWeight

        let blendedMean = personalWeight * personalMean + priorWeight * prior.mean
        let blendedStdev = personalWeight * max(personalStdev, 0.001) + priorWeight * prior.stdev

        return (blendedMean, blendedStdev)
    }

    // MARK: - Sleep Deficit

    private func computeSleepDeficit(sleepTonight: Double?, personalSleepValues: [Double], prior: PopulationPrior, dayCount: Int) -> Double {
        guard let sleepTonight = sleepTonight else { return 0.0 }

        let (avgSleep, _) = blendedMeanAndStdev(
            personalValues: personalSleepValues,
            prior: prior,
            dayCount: dayCount
        )

        guard avgSleep > 0 else { return 0.0 }

        let deficit = (avgSleep - sleepTonight) / avgSleep
        return min(max(deficit, 0.0), 1.0)
    }

    // MARK: - Baseline Management

    func updateBaseline(_ baseline: inout BaselineData, with metrics: NightlyMetrics, excludeFromBaseline: Bool = false) {
        guard !excludeFromBaseline else { return }

        // Helper to add value with outlier protection and 14-day cap
        func addIfValid(_ value: Double?, to array: inout [Double], prior: PopulationPrior, dayCount: Int) {
            guard let value = value else { return }

            // Outlier protection: skip values outside ±3 stdev of current baseline
            if !array.isEmpty {
                let (mean, stdev) = blendedMeanAndStdev(personalValues: array, prior: prior, dayCount: dayCount)
                if stdev > 0 && abs(value - mean) > 3.0 * stdev {
                    return // Skip outlier
                }
            }

            array.append(value)
            if array.count > 14 {
                array.removeFirst()
            }
        }

        let dayCount = baseline.dates.count

        addIfValid(metrics.hrv, to: &baseline.hrvValues, prior: hrvPrior, dayCount: dayCount)
        addIfValid(metrics.rhr, to: &baseline.rhrValues, prior: rhrPrior, dayCount: dayCount)
        addIfValid(metrics.respRate, to: &baseline.respRateValues, prior: respRatePrior, dayCount: dayCount)
        addIfValid(metrics.wristTemp, to: &baseline.wristTempValues, prior: wristTempPrior, dayCount: dayCount)
        addIfValid(metrics.sleepDuration, to: &baseline.sleepDurations, prior: sleepDurationPrior, dayCount: dayCount)

        baseline.dates.append(metrics.date)
        if baseline.dates.count > 14 {
            baseline.dates.removeFirst()
        }
    }

    // MARK: - Persistence

    func loadBaseline() -> BaselineData {
        guard let data = UserDefaults.standard.data(forKey: baselineKey),
              let baseline = try? JSONDecoder().decode(BaselineData.self, from: data) else {
            return .empty
        }
        return baseline
    }

    func saveBaseline(_ baseline: BaselineData) {
        if let data = try? JSONEncoder().encode(baseline) {
            UserDefaults.standard.set(data, forKey: baselineKey)
        }
    }

    func loadScoreHistory() -> [StressRecoveryScore] {
        guard let data = UserDefaults.standard.data(forKey: scoresKey),
              let entries = try? JSONDecoder().decode([StoredScore].self, from: data) else {
            return []
        }
        return entries.map { $0.toScore() }
    }

    func saveScoreHistory(_ scores: [StressRecoveryScore]) {
        let storable = scores.suffix(7).map { StoredScore(from: $0) }
        if let data = try? JSONEncoder().encode(storable) {
            UserDefaults.standard.set(data, forKey: scoresKey)
        }
    }

    // MARK: - Helpers

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let sumOfSquares = values.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) }
        return sqrt(sumOfSquares / Double(values.count - 1))
    }
}

// MARK: - Codable Score Storage

private struct StoredScore: Codable {
    let date: Date
    let stressScore: Int
    let recoveryScore: Int
    let stressRaw: Double
    let zHRV: Double?
    let zRHR: Double?
    let zResp: Double?
    let zTemp: Double?
    let sleepDeficit: Double
    let hasTemperatureData: Bool

    init(from score: StressRecoveryScore) {
        self.date = score.date
        self.stressScore = score.stressScore
        self.recoveryScore = score.recoveryScore
        self.stressRaw = score.stressRaw
        self.zHRV = score.zScores.hrv
        self.zRHR = score.zScores.rhr
        self.zResp = score.zScores.respRate
        self.zTemp = score.zScores.wristTemp
        self.sleepDeficit = score.sleepDeficit
        self.hasTemperatureData = score.hasTemperatureData
    }

    func toScore() -> StressRecoveryScore {
        StressRecoveryScore(
            date: date,
            stressScore: stressScore,
            recoveryScore: recoveryScore,
            stressRaw: stressRaw,
            zScores: MetricZScores(hrv: zHRV, rhr: zRHR, respRate: zResp, wristTemp: zTemp),
            sleepDeficit: sleepDeficit,
            hasTemperatureData: hasTemperatureData
        )
    }
}
