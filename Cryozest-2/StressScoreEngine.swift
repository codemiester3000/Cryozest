import Foundation

// MARK: - Data Structures

struct NightlyMetrics {
    let date: Date
    let hrv: Double?           // SDNN tonight (ms)
    let rhr: Double?           // Resting heart rate tonight (bpm)
    let respRate: Double?      // Respiratory rate during sleep (br/min)
    let wristTemp: Double?     // Wrist temp deviation (°C), nil if unavailable
    let sleepDuration: Double? // Total sleep in seconds

    // MARK: - Data Quality Validation

    /// Minimum sleep required to generate a score (2 hours in seconds).
    /// WHOOP requires detected sleep; Oura requires 3 hours of sleep stages.
    /// We use 2 hours as a conservative lower bound.
    static let minimumSleepForScore: Double = 7200.0

    /// Returns true if this night has enough data to produce a reliable score.
    /// Requirements (modeled after WHOOP/Oura):
    ///   1. Sleep must be detected AND >= 2 hours
    ///   2. HRV during sleep must exist (primary recovery signal)
    ///   3. RHR must exist (secondary signal, but always present if watch was worn during sleep)
    var hasSufficientData: Bool {
        guard let sleep = sleepDuration, sleep >= NightlyMetrics.minimumSleepForScore else {
            return false
        }
        guard hrv != nil else {
            return false
        }
        // RHR is also required — if the watch recorded sleep + HRV, RHR should always exist.
        // If it doesn't, something is wrong with the data.
        guard rhr != nil else {
            return false
        }
        return true
    }

    /// Returns the count of available optional metrics (resp rate, wrist temp)
    /// beyond the mandatory trio (HRV, RHR, sleep).
    var availableOptionalMetricCount: Int {
        var count = 0
        if respRate != nil { count += 1 }
        if wristTemp != nil { count += 1 }
        return count
    }
}

struct StressRecoveryScore {
    let date: Date
    let stressScore: Int       // 0-100, higher = more stressed
    let recoveryScore: Int     // 0-100, higher = more recovered
    let stressRaw: Double      // Raw stress value before scaling
    let zScores: MetricZScores
    let sleepDeficit: Double
    let hasTemperatureData: Bool
    let dataQuality: DataQuality

    enum DataQuality: String {
        case full           // All 5 metrics present
        case noTemp         // Missing wrist temp (device doesn't support or not enough nights)
        case partial        // Missing resp rate or temp
        case insufficient   // Not enough data to produce a score
    }
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
    var dates: [Date]              // corresponding dates (only nights with sufficient data)

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

    // Base weights (when all 5 metrics are present)
    // HRV: 35%, RHR: 25%, Resp: 15%, Temp: 10%, Sleep: 15%
    private struct MetricWeights {
        let hrv: Double
        let rhr: Double
        let resp: Double
        let temp: Double
        let sleep: Double
    }

    // Scaling factor: ±3 stdev maps to full 0-100 range
    private let scalingFactor: Double = 16.67

    private let baselineKey = "stressScoreBaseline"
    private let scoresKey = "stressScoreHistory"

    private init() {}

    // MARK: - Dynamic Weight Computation

    /// Computes weights dynamically based on which metrics are actually present.
    /// Only redistributes among metrics that have data — never assumes "average" for missing data.
    private func weights(hasHRV: Bool, hasRHR: Bool, hasResp: Bool, hasTemp: Bool) -> MetricWeights {
        // Base weights
        var wHRV: Double = hasHRV ? 0.35 : 0.0
        var wRHR: Double = hasRHR ? 0.25 : 0.0
        var wResp: Double = hasResp ? 0.15 : 0.0
        var wTemp: Double = hasTemp ? 0.10 : 0.0
        let wSleep: Double = 0.15  // Sleep deficit is always computable if sleep exists

        // Total weight assigned to present metrics
        let assignedWeight = wHRV + wRHR + wResp + wTemp + wSleep

        // Normalize so weights sum to 1.0 (redistribute missing weight proportionally)
        if assignedWeight > 0 && assignedWeight < 1.0 {
            let scale = 1.0 / assignedWeight
            wHRV *= scale
            wRHR *= scale
            wResp *= scale
            wTemp *= scale
            // wSleep is handled separately since it's always present
            // Actually, scale all together:
        }

        // Simpler approach: redistribute missing optional metric weight to the core metrics
        // HRV and RHR are mandatory, so they're always present at this point.
        // Only resp and temp are optional.
        if !hasTemp && !hasResp {
            // Only HRV (35%), RHR (25%), Sleep (15%) = 75% -> scale to 100%
            // Redistribute 25% proportionally among HRV, RHR, Sleep
            return MetricWeights(
                hrv: -0.467,  // 0.35/0.75
                rhr: 0.333,   // 0.25/0.75
                resp: 0.0,
                temp: 0.0,
                sleep: 0.200  // 0.15/0.75
            )
        } else if !hasTemp {
            // HRV (35%), RHR (25%), Resp (15%), Sleep (15%) = 90% -> scale to 100%
            return MetricWeights(
                hrv: -0.389,  // 0.35/0.90
                rhr: 0.278,   // 0.25/0.90
                resp: 0.167,  // 0.15/0.90
                temp: 0.0,
                sleep: 0.167  // 0.15/0.90
            )
        } else if !hasResp {
            // HRV (35%), RHR (25%), Temp (10%), Sleep (15%) = 85% -> scale to 100%
            return MetricWeights(
                hrv: -0.412,  // 0.35/0.85
                rhr: 0.294,   // 0.25/0.85
                resp: 0.0,
                temp: 0.118,  // 0.10/0.85
                sleep: 0.176  // 0.15/0.85
            )
        } else {
            // All metrics present
            return MetricWeights(
                hrv: -0.35,
                rhr: 0.25,
                resp: 0.15,
                temp: 0.10,
                sleep: 0.15
            )
        }
    }

    // MARK: - Score Computation

    /// Computes stress and recovery scores from nightly metrics.
    /// Returns nil if metrics don't meet minimum data quality requirements.
    func computeScore(metrics: NightlyMetrics, baseline: BaselineData) -> StressRecoveryScore? {
        // GATE: Require sufficient data (sleep >= 2h + HRV + RHR)
        // This matches WHOOP (no score without detected sleep) and Oura (min 3h sleep stages)
        guard metrics.hasSufficientData else {
            return nil
        }

        let dayCount = baseline.dates.count
        let hasTemp = metrics.wristTemp != nil
        let hasResp = metrics.respRate != nil

        // Compute Z-scores (only for present metrics)
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

        // Get dynamically computed weights based on available metrics
        let w = weights(hasHRV: true, hasRHR: true, hasResp: hasResp, hasTemp: hasTemp)

        // Combine into raw stress score — only use metrics that actually exist
        var stressRaw: Double = 0.0
        stressRaw += w.hrv * (zHRV ?? 0.0)    // HRV is mandatory, zHRV should never be nil here
        stressRaw += w.rhr * (zRHR ?? 0.0)    // RHR is mandatory, zRHR should never be nil here
        if let zR = zResp { stressRaw += w.resp * zR }
        if let zT = zTemp { stressRaw += w.temp * zT }
        stressRaw += w.sleep * sleepDeficit

        // Scale to 0-100
        let recoveryRaw = 50.0 - (stressRaw * scalingFactor)
        let stressScaled = 50.0 + (stressRaw * scalingFactor)

        let recoveryScore = Int(min(max(recoveryRaw, 0), 100).rounded())
        let stressScore = Int(min(max(stressScaled, 0), 100).rounded())

        // Determine data quality
        let quality: StressRecoveryScore.DataQuality
        if hasTemp && hasResp {
            quality = .full
        } else if !hasTemp && hasResp {
            quality = .noTemp
        } else {
            quality = .partial
        }

        return StressRecoveryScore(
            date: metrics.date,
            stressScore: stressScore,
            recoveryScore: recoveryScore,
            stressRaw: stressRaw,
            zScores: MetricZScores(hrv: zHRV, rhr: zRHR, respRate: zResp, wristTemp: zTemp),
            sleepDeficit: sleepDeficit,
            hasTemperatureData: hasTemp,
            dataQuality: quality
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

    /// Updates the rolling 14-day baseline with new nightly data.
    /// IMPORTANT: Only call this when metrics.hasSufficientData is true.
    /// Nights where the watch wasn't worn or sleep < 2h should NEVER enter the baseline.
    func updateBaseline(_ baseline: inout BaselineData, with metrics: NightlyMetrics) {
        // Double-check: never pollute baseline with insufficient data
        guard metrics.hasSufficientData else { return }

        // Don't add duplicate dates
        let calendar = Calendar.current
        let metricsDay = calendar.startOfDay(for: metrics.date)
        if baseline.dates.contains(where: { calendar.startOfDay(for: $0) == metricsDay }) {
            return
        }

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

        // HRV, RHR, and sleep are guaranteed non-nil because hasSufficientData is true
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

    /// Clears persisted baseline — useful for debugging or reset
    func resetBaseline() {
        UserDefaults.standard.removeObject(forKey: baselineKey)
        UserDefaults.standard.removeObject(forKey: scoresKey)
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
    let dataQualityRaw: String?

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
        self.dataQualityRaw = score.dataQuality.rawValue
    }

    func toScore() -> StressRecoveryScore {
        let quality = StressRecoveryScore.DataQuality(rawValue: dataQualityRaw ?? "full") ?? .full
        return StressRecoveryScore(
            date: date,
            stressScore: stressScore,
            recoveryScore: recoveryScore,
            stressRaw: stressRaw,
            zScores: MetricZScores(hrv: zHRV, rhr: zRHR, respRate: zResp, wristTemp: zTemp),
            sleepDeficit: sleepDeficit,
            hasTemperatureData: hasTemperatureData,
            dataQuality: quality
        )
    }
}
