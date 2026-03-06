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

    /// Returns true if this night has enough data for a **recovery** score.
    /// Recovery is specifically about recovering from sleep, so it requires:
    ///   1. Sleep must be detected AND >= 2 hours
    ///   2. HRV during sleep must exist (primary recovery signal)
    ///   3. RHR must exist (always present if watch was worn during sleep)
    var hasSufficientDataForRecovery: Bool {
        guard let sleep = sleepDuration, sleep >= NightlyMetrics.minimumSleepForScore else {
            return false
        }
        guard hrv != nil else {
            return false
        }
        guard rhr != nil else {
            return false
        }
        return true
    }

    /// Returns true if this night/day has enough data for a **stress** score.
    /// Stress only requires the two core physiological signals (HRV + RHR).
    /// Sleep, resp rate, and wrist temp are optional enhancers that improve accuracy
    /// but are not required. This allows stress scores even when sleep data
    /// hasn't synced yet or wasn't recorded.
    var hasSufficientDataForStress: Bool {
        guard hrv != nil else { return false }
        guard rhr != nil else { return false }
        return true
    }

    /// Legacy alias — recovery-level sufficiency (strictest gate).
    var hasSufficientData: Bool { hasSufficientDataForRecovery }

    /// Returns true if sleep data is present and meets the minimum threshold.
    var hasSleepData: Bool {
        guard let sleep = sleepDuration, sleep >= NightlyMetrics.minimumSleepForScore else {
            return false
        }
        return true
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
    let computedWeights: ComputedWeights
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

struct ComputedWeights {
    let hrv: Double
    let rhr: Double
    let resp: Double
    let temp: Double
    let sleep: Double

    /// Returns the weight as a percentage string (e.g. "35%")
    func label(for metric: String) -> String {
        let value: Double
        switch metric {
        case "hrv":   value = hrv
        case "rhr":   value = rhr
        case "resp":  value = resp
        case "temp":  value = temp
        case "sleep": value = sleep
        default:      value = 0
        }
        return "\(Int((value * 100).rounded()))%"
    }
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

        var asPublic: ComputedWeights {
            ComputedWeights(hrv: hrv, rhr: rhr, resp: resp, temp: temp, sleep: sleep)
        }
    }

    // Scaling factor: ±3 stdev maps to full 0-100 range
    private let scalingFactor: Double = 16.67

    private let baselineKey = "stressScoreBaseline"
    private let scoresKey = "stressScoreHistory"

    private init() {}

    // MARK: - Dynamic Weight Computation

    // Base weights (absolute values) — all positive.
    // The sign convention for each metric is handled at combination time, NOT in the weight.
    //   • HRV: higher = LESS stress, so z_hrv is NEGATED when combining
    //   • RHR, Resp, Temp, Sleep deficit: higher = MORE stress, used as-is
    private static let baseWeights: [String: Double] = [
        "hrv": 0.35,
        "rhr": 0.25,
        "resp": 0.15,
        "temp": 0.10,
        "sleep": 0.15
    ]

    /// Computes weights dynamically based on which metrics are actually present.
    /// HRV and RHR are always required (guaranteed by hasSufficientDataForStress).
    /// Sleep, resp, and temp are optional — their weight is redistributed proportionally
    /// among present metrics when missing.
    private func weights(hasResp: Bool, hasTemp: Bool, hasSleep: Bool = true) -> MetricWeights {
        // Start with base weights for mandatory metrics
        var pool: [String: Double] = [
            "hrv": Self.baseWeights["hrv"]!,
            "rhr": Self.baseWeights["rhr"]!,
        ]

        // Add optional metrics that are present
        if hasSleep { pool["sleep"] = Self.baseWeights["sleep"]! }
        if hasResp { pool["resp"] = Self.baseWeights["resp"]! }
        if hasTemp { pool["temp"] = Self.baseWeights["temp"]! }

        // Normalize so weights sum to 1.0
        let total = pool.values.reduce(0, +)
        let scale = total > 0 ? (1.0 / total) : 1.0

        return MetricWeights(
            hrv: (pool["hrv"] ?? 0) * scale,
            rhr: (pool["rhr"] ?? 0) * scale,
            resp: (pool["resp"] ?? 0) * scale,
            temp: (pool["temp"] ?? 0) * scale,
            sleep: (pool["sleep"] ?? 0) * scale
        )
    }

    // MARK: - Score Computation

    /// Computes stress and recovery scores from nightly metrics.
    ///
    /// - Parameter requireSleep: When `true` (default), requires sleep ≥ 2h + HRV + RHR
    ///   (full recovery-level gating). When `false`, only HRV + RHR are required and sleep
    ///   is treated as an optional enhancer — use this for stress-only scoring.
    /// - Returns: nil if metrics don't meet the minimum requirements for the requested mode.
    func computeScore(metrics: NightlyMetrics, baseline: BaselineData, requireSleep: Bool = true) -> StressRecoveryScore? {
        // GATE: Check data sufficiency based on mode
        if requireSleep {
            // Recovery mode: need sleep + HRV + RHR (matches WHOOP/Oura)
            guard metrics.hasSufficientDataForRecovery else { return nil }
        } else {
            // Stress-only mode: just need HRV + RHR
            guard metrics.hasSufficientDataForStress else { return nil }
        }

        let hasTemp = metrics.wristTemp != nil
        let hasResp = metrics.respRate != nil
        let hasSleep = metrics.hasSleepData

        // Use per-metric array count for cold-start blending (not baseline.dates.count).
        // Each metric array can differ in length — e.g., wrist temp is only available on
        // newer devices, so wristTempValues may have fewer entries than hrvValues.
        let zHRV = computeZScore(
            value: metrics.hrv,
            personalValues: baseline.hrvValues,
            prior: hrvPrior,
            dayCount: baseline.hrvValues.count
        )

        let zRHR = computeZScore(
            value: metrics.rhr,
            personalValues: baseline.rhrValues,
            prior: rhrPrior,
            dayCount: baseline.rhrValues.count
        )

        let zResp = computeZScore(
            value: metrics.respRate,
            personalValues: baseline.respRateValues,
            prior: respRatePrior,
            dayCount: baseline.respRateValues.count
        )

        let zTemp: Double? = hasTemp ? computeZScore(
            value: metrics.wristTemp,
            personalValues: baseline.wristTempValues,
            prior: wristTempPrior,
            dayCount: baseline.wristTempValues.count
        ) : nil

        // Sleep deficit (returns 0 when sleep data is absent)
        let sleepDeficit = computeSleepDeficit(
            sleepTonight: metrics.sleepDuration,
            personalSleepValues: baseline.sleepDurations,
            prior: sleepDurationPrior,
            dayCount: baseline.sleepDurations.count
        )

        // Get dynamically computed weights based on available metrics
        let w = weights(hasResp: hasResp, hasTemp: hasTemp, hasSleep: hasSleep)

        // Combine into raw stress score.
        // SIGN CONVENTION (explicit):
        //   • HRV: higher z = better recovery = LESS stress → NEGATE the z-score
        //   • RHR: higher z = more stressed → use as-is (positive)
        //   • Resp: higher z = more stressed → use as-is (positive)
        //   • Temp: higher z = more stressed → use as-is (positive)
        //   • Sleep deficit: higher = more stressed → use as-is (positive)
        var stressRaw: Double = 0.0
        stressRaw += w.hrv * (-(zHRV ?? 0.0))  // NEGATE: high HRV = low stress
        stressRaw += w.rhr * (zRHR ?? 0.0)     // RHR is mandatory, zRHR should never be nil here
        if let zR = zResp { stressRaw += w.resp * zR }
        if let zT = zTemp { stressRaw += w.temp * zT }
        if hasSleep { stressRaw += w.sleep * sleepDeficit }

        // Scale to 0-100
        let recoveryRaw = 50.0 - (stressRaw * scalingFactor)
        let stressScaled = 50.0 + (stressRaw * scalingFactor)

        let recoveryScore = Int(min(max(recoveryRaw, 0), 100).rounded())
        let stressScore = Int(min(max(stressScaled, 0), 100).rounded())

        // Determine data quality
        let quality: StressRecoveryScore.DataQuality
        if hasTemp && hasResp && hasSleep {
            quality = .full
        } else if !hasTemp && hasResp && hasSleep {
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
            computedWeights: w.asPublic,
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
    /// IMPORTANT: Only call this when metrics.hasSufficientDataForRecovery is true.
    /// Nights where the watch wasn't worn or sleep < 2h should NEVER enter the baseline
    /// because baseline quality requires full overnight data for all core metrics.
    func updateBaseline(_ baseline: inout BaselineData, with metrics: NightlyMetrics) {
        // Double-check: never pollute baseline with insufficient data
        guard metrics.hasSufficientDataForRecovery else { return }

        // Don't add duplicate dates
        let calendar = Calendar.current
        let metricsDay = calendar.startOfDay(for: metrics.date)
        if baseline.dates.contains(where: { calendar.startOfDay(for: $0) == metricsDay }) {
            return
        }

        // Helper to add value with outlier protection and 14-day cap.
        // NOTE: Each metric array is managed independently. An outlier skip for one metric
        // does NOT prevent other metrics from being added. This means baseline arrays can
        // have different counts (e.g. hrvValues.count != rhrValues.count). This is by design:
        // computeZScore uses each metric's own array count for cold-start blending, so the
        // independence is correct. Do NOT assume array indices correspond across metrics.
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

        // HRV and RHR are guaranteed non-nil; sleep may be nil in stress-only mode
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
    // Persisted weights so historical scores display the correct labels
    let wHRV: Double?
    let wRHR: Double?
    let wResp: Double?
    let wTemp: Double?
    let wSleep: Double?

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
        self.wHRV = score.computedWeights.hrv
        self.wRHR = score.computedWeights.rhr
        self.wResp = score.computedWeights.resp
        self.wTemp = score.computedWeights.temp
        self.wSleep = score.computedWeights.sleep
    }

    func toScore() -> StressRecoveryScore {
        let quality = StressRecoveryScore.DataQuality(rawValue: dataQualityRaw ?? "full") ?? .full
        // Reconstruct weights; fall back to equal-ish defaults for scores stored before this field existed
        let weights = ComputedWeights(
            hrv: wHRV ?? 0.35,
            rhr: wRHR ?? 0.25,
            resp: wResp ?? 0.15,
            temp: wTemp ?? 0.10,
            sleep: wSleep ?? 0.15
        )
        return StressRecoveryScore(
            date: date,
            stressScore: stressScore,
            recoveryScore: recoveryScore,
            stressRaw: stressRaw,
            zScores: MetricZScores(hrv: zHRV, rhr: zRHR, respRate: zResp, wristTemp: zTemp),
            sleepDeficit: sleepDeficit,
            hasTemperatureData: hasTemperatureData,
            computedWeights: weights,
            dataQuality: quality
        )
    }
}
