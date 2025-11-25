//
//  StatisticsUtility.swift
//  Cryozest-2
//
//  Robust statistical analysis for habit-health correlations
//

import Foundation

// MARK: - Statistical Result Types

struct CorrelationResult {
    let coefficient: Double          // Pearson r: -1 to 1
    let pValue: Double               // Statistical significance
    let sampleSize: Int
    let confidenceInterval: (lower: Double, upper: Double)

    var isSignificant: Bool {
        pValue < 0.05 && sampleSize >= StatisticsUtility.minimumSampleSize
    }

    var confidenceLevel: ConfidenceLevel {
        if sampleSize < StatisticsUtility.minimumSampleSize {
            return .insufficient
        } else if pValue < 0.01 && sampleSize >= 30 {
            return .high
        } else if pValue < 0.05 && sampleSize >= 14 {
            return .moderate
        } else if pValue < 0.10 {
            return .low
        } else {
            return .insufficient
        }
    }

    var strengthDescription: String {
        let absR = abs(coefficient)
        if absR >= 0.7 { return "Strong" }
        if absR >= 0.4 { return "Moderate" }
        if absR >= 0.2 { return "Weak" }
        return "Very weak"
    }
}

enum ConfidenceLevel: String, CaseIterable {
    case high = "High Confidence"
    case moderate = "Moderate Confidence"
    case low = "Low Confidence"
    case insufficient = "Insufficient Data"

    var color: String {
        switch self {
        case .high: return "green"
        case .moderate: return "yellow"
        case .low: return "orange"
        case .insufficient: return "gray"
        }
    }

    var iconFillAmount: Double {
        switch self {
        case .high: return 1.0
        case .moderate: return 0.66
        case .low: return 0.33
        case .insufficient: return 0.0
        }
    }
}

struct LaggedCorrelation {
    let lagDays: Int
    let result: CorrelationResult

    var description: String {
        if lagDays == 0 {
            return "Same day"
        } else if lagDays == 1 {
            return "Next day"
        } else {
            return "\(lagDays) days later"
        }
    }
}

struct RegressionResult {
    let coefficients: [String: Double]  // habit name -> coefficient
    let intercept: Double
    let rSquared: Double                 // Explained variance (0-1)
    let adjustedRSquared: Double
    let fStatistic: Double
    let pValue: Double
    let sampleSize: Int

    var isSignificant: Bool {
        pValue < 0.05 && sampleSize >= StatisticsUtility.minimumSampleSize
    }
}

// MARK: - Statistics Utility

class StatisticsUtility {
    static let shared = StatisticsUtility()

    /// Minimum sample size for reliable statistics
    static let minimumSampleSize = 14

    /// Minimum sample size for high confidence
    static let highConfidenceSampleSize = 30

    private init() {}

    // MARK: - Outlier Detection

    /// Remove outliers using IQR method
    func removeOutliers(_ values: [Double], multiplier: Double = 1.5) -> [Double] {
        guard values.count >= 4 else { return values }

        let sorted = values.sorted()
        let q1 = percentile(sorted, 25)
        let q3 = percentile(sorted, 75)
        let iqr = q3 - q1

        let lowerBound = q1 - multiplier * iqr
        let upperBound = q3 + multiplier * iqr

        return values.filter { $0 >= lowerBound && $0 <= upperBound }
    }

    /// Remove outliers from paired data (keeps pairs intact)
    func removeOutliersPaired(_ x: [Double], _ y: [Double], multiplier: Double = 1.5) -> ([Double], [Double]) {
        guard x.count == y.count, x.count >= 4 else { return (x, y) }

        let xSorted = x.sorted()
        let ySorted = y.sorted()

        let xQ1 = percentile(xSorted, 25)
        let xQ3 = percentile(xSorted, 75)
        let xIQR = xQ3 - xQ1

        let yQ1 = percentile(ySorted, 25)
        let yQ3 = percentile(ySorted, 75)
        let yIQR = yQ3 - yQ1

        let xLower = xQ1 - multiplier * xIQR
        let xUpper = xQ3 + multiplier * xIQR
        let yLower = yQ1 - multiplier * yIQR
        let yUpper = yQ3 + multiplier * yIQR

        var filteredX: [Double] = []
        var filteredY: [Double] = []

        for i in 0..<x.count {
            if x[i] >= xLower && x[i] <= xUpper && y[i] >= yLower && y[i] <= yUpper {
                filteredX.append(x[i])
                filteredY.append(y[i])
            }
        }

        return (filteredX, filteredY)
    }

    private func percentile(_ sortedValues: [Double], _ p: Double) -> Double {
        guard !sortedValues.isEmpty else { return 0 }

        let index = (p / 100.0) * Double(sortedValues.count - 1)
        let lower = Int(floor(index))
        let upper = Int(ceil(index))

        if lower == upper {
            return sortedValues[lower]
        }

        let weight = index - Double(lower)
        return sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight
    }

    // MARK: - Correlation Analysis

    /// Calculate Pearson correlation coefficient with p-value and confidence interval
    func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> CorrelationResult? {
        guard x.count == y.count, x.count >= 3 else { return nil }

        // Remove outliers first
        let (cleanX, cleanY) = removeOutliersPaired(x, y)
        guard cleanX.count >= 3 else { return nil }

        let n = Double(cleanX.count)

        let sumX = cleanX.reduce(0, +)
        let sumY = cleanY.reduce(0, +)
        let sumXY = zip(cleanX, cleanY).map(*).reduce(0, +)
        let sumX2 = cleanX.map { $0 * $0 }.reduce(0, +)
        let sumY2 = cleanY.map { $0 * $0 }.reduce(0, +)

        let numerator = (n * sumXY) - (sumX * sumY)
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator != 0 else {
            return CorrelationResult(
                coefficient: 0,
                pValue: 1.0,
                sampleSize: cleanX.count,
                confidenceInterval: (-1, 1)
            )
        }

        let r = numerator / denominator
        let clampedR = max(-1, min(1, r)) // Clamp to valid range

        // Calculate p-value using t-distribution approximation
        let pValue = calculatePValue(r: clampedR, n: cleanX.count)

        // Calculate 95% confidence interval using Fisher's z-transformation
        let ci = fisherConfidenceInterval(r: clampedR, n: cleanX.count)

        return CorrelationResult(
            coefficient: clampedR,
            pValue: pValue,
            sampleSize: cleanX.count,
            confidenceInterval: ci
        )
    }

    /// Calculate p-value for correlation coefficient
    private func calculatePValue(r: Double, n: Int) -> Double {
        guard n > 2 else { return 1.0 }

        let df = Double(n - 2)
        let t = r * sqrt(df / (1 - r * r))

        // Two-tailed t-test p-value approximation
        return tDistributionPValue(t: abs(t), df: df)
    }

    /// Approximate t-distribution p-value (two-tailed)
    private func tDistributionPValue(t: Double, df: Double) -> Double {
        // Using approximation for t-distribution CDF
        let x = df / (df + t * t)
        let a = df / 2.0
        let b = 0.5

        // Regularized incomplete beta function approximation
        let betaValue = incompleteBeta(a: a, b: b, x: x)
        return betaValue
    }

    /// Incomplete beta function approximation
    private func incompleteBeta(a: Double, b: Double, x: Double) -> Double {
        // Simple approximation using continued fraction
        // For more accuracy, consider using a library
        if x == 0 { return 0 }
        if x == 1 { return 1 }

        // Use normal approximation for large df
        if a > 30 {
            let z = sqrt(2 * a) * (pow(x / (1 - x), 1.0/3.0) - 1 + 1.0 / (9 * a))
            return normalCDF(-z) * 2 // Two-tailed
        }

        // Simple numerical approximation for smaller df
        var sum = 0.0
        let steps = 1000
        let dx = x / Double(steps)

        for i in 0..<steps {
            let xi = (Double(i) + 0.5) * dx
            sum += pow(xi, a - 1) * pow(1 - xi, b - 1) * dx
        }

        // Normalize (approximate)
        let beta = tgamma(a) * tgamma(b) / tgamma(a + b)
        return min(1.0, sum / beta)
    }

    /// Standard normal CDF approximation
    private func normalCDF(_ x: Double) -> Double {
        let t = 1.0 / (1.0 + 0.2316419 * abs(x))
        let d = 0.3989423 * exp(-x * x / 2.0)
        let p = d * t * (0.3193815 + t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))))
        return x > 0 ? 1 - p : p
    }

    /// Fisher's z-transformation for confidence interval
    private func fisherConfidenceInterval(r: Double, n: Int, confidence: Double = 0.95) -> (lower: Double, upper: Double) {
        guard n > 3 else { return (-1, 1) }

        // Fisher's z-transformation
        let z = 0.5 * log((1 + r) / (1 - r))
        let se = 1.0 / sqrt(Double(n - 3))

        // Z-score for confidence level (1.96 for 95%)
        let zScore = confidence == 0.95 ? 1.96 : 2.576 // 95% or 99%

        let zLower = z - zScore * se
        let zUpper = z + zScore * se

        // Transform back
        let rLower = (exp(2 * zLower) - 1) / (exp(2 * zLower) + 1)
        let rUpper = (exp(2 * zUpper) - 1) / (exp(2 * zUpper) + 1)

        return (max(-1, rLower), min(1, rUpper))
    }

    // MARK: - Lag Analysis

    /// Calculate correlations at different lag periods (0, 1, 2 days)
    func laggedCorrelations(
        habitDates: [Date],
        metricData: [(date: Date, value: Double)],
        maxLag: Int = 2
    ) -> [LaggedCorrelation] {
        var results: [LaggedCorrelation] = []
        let calendar = Calendar.current

        for lag in 0...maxLag {
            var x: [Double] = [] // 1 if habit done, 0 if not
            var y: [Double] = [] // metric value

            // Build aligned data
            let habitDateSet = Set(habitDates.map { calendar.startOfDay(for: $0) })

            for metric in metricData {
                let metricDate = calendar.startOfDay(for: metric.date)

                // Check if habit was done `lag` days before this metric reading
                guard let habitCheckDate = calendar.date(byAdding: .day, value: -lag, to: metricDate) else {
                    continue
                }

                let habitDone = habitDateSet.contains(habitCheckDate)
                x.append(habitDone ? 1.0 : 0.0)
                y.append(metric.value)
            }

            if let result = pearsonCorrelation(x, y) {
                results.append(LaggedCorrelation(lagDays: lag, result: result))
            }
        }

        return results
    }

    /// Find the optimal lag (highest significant correlation)
    func optimalLag(from laggedResults: [LaggedCorrelation]) -> LaggedCorrelation? {
        return laggedResults
            .filter { $0.result.isSignificant }
            .max { abs($0.result.coefficient) < abs($1.result.coefficient) }
    }

    // MARK: - Multi-Habit Regression

    /// Simple multiple linear regression for attributing effects to multiple habits
    func multipleRegression(
        habitPresence: [[Double]],  // Each row is a day, each column is a habit (1=done, 0=not)
        outcome: [Double],          // Health metric values
        habitNames: [String]
    ) -> RegressionResult? {
        let n = outcome.count
        let p = habitNames.count

        guard n > p + 1, n >= StatisticsUtility.minimumSampleSize else { return nil }

        // Add intercept column (all 1s)
        let X: [[Double]] = habitPresence.map { [1.0] + $0 }
        let y = outcome

        // Solve using normal equations: β = (X'X)^(-1) X'y
        // This is a simplified implementation - for production, use a proper linear algebra library

        guard let coefficients = solveNormalEquations(X: X, y: y) else { return nil }

        let intercept = coefficients[0]
        var habitCoefficients: [String: Double] = [:]
        for (i, name) in habitNames.enumerated() {
            habitCoefficients[name] = coefficients[i + 1]
        }

        // Calculate R-squared
        let yMean = y.reduce(0, +) / Double(n)
        var ssTot = 0.0
        var ssRes = 0.0

        for i in 0..<n {
            let predicted = dotProduct(X[i], coefficients)
            ssRes += pow(y[i] - predicted, 2)
            ssTot += pow(y[i] - yMean, 2)
        }

        let rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0
        let adjustedRSquared = 1 - (1 - rSquared) * Double(n - 1) / Double(n - p - 1)

        // F-statistic for overall model significance
        let ssReg = ssTot - ssRes
        let fStatistic = (ssReg / Double(p)) / (ssRes / Double(n - p - 1))

        // Approximate p-value for F-statistic
        let pValue = fDistributionPValue(f: fStatistic, df1: Double(p), df2: Double(n - p - 1))

        return RegressionResult(
            coefficients: habitCoefficients,
            intercept: intercept,
            rSquared: rSquared,
            adjustedRSquared: adjustedRSquared,
            fStatistic: fStatistic,
            pValue: pValue,
            sampleSize: n
        )
    }

    /// Solve normal equations using Gaussian elimination
    private func solveNormalEquations(X: [[Double]], y: [Double]) -> [Double]? {
        let n = X.count
        let p = X[0].count

        // Calculate X'X
        var XtX = [[Double]](repeating: [Double](repeating: 0, count: p), count: p)
        for i in 0..<p {
            for j in 0..<p {
                for k in 0..<n {
                    XtX[i][j] += X[k][i] * X[k][j]
                }
            }
        }

        // Calculate X'y
        var Xty = [Double](repeating: 0, count: p)
        for i in 0..<p {
            for k in 0..<n {
                Xty[i] += X[k][i] * y[k]
            }
        }

        // Solve using Gaussian elimination with partial pivoting
        return gaussianElimination(matrix: XtX, vector: Xty)
    }

    private func gaussianElimination(matrix: [[Double]], vector: [Double]) -> [Double]? {
        var A = matrix
        var b = vector
        let n = A.count

        // Forward elimination
        for i in 0..<n {
            // Find pivot
            var maxRow = i
            for k in (i + 1)..<n {
                if abs(A[k][i]) > abs(A[maxRow][i]) {
                    maxRow = k
                }
            }

            // Swap rows
            A.swapAt(i, maxRow)
            b.swapAt(i, maxRow)

            // Check for singular matrix
            if abs(A[i][i]) < 1e-10 { return nil }

            // Eliminate column
            for k in (i + 1)..<n {
                let factor = A[k][i] / A[i][i]
                for j in i..<n {
                    A[k][j] -= factor * A[i][j]
                }
                b[k] -= factor * b[i]
            }
        }

        // Back substitution
        var x = [Double](repeating: 0, count: n)
        for i in (0..<n).reversed() {
            x[i] = b[i]
            for j in (i + 1)..<n {
                x[i] -= A[i][j] * x[j]
            }
            x[i] /= A[i][i]
        }

        return x
    }

    private func dotProduct(_ a: [Double], _ b: [Double]) -> Double {
        zip(a, b).map(*).reduce(0, +)
    }

    /// Approximate F-distribution p-value
    private func fDistributionPValue(f: Double, df1: Double, df2: Double) -> Double {
        // Use normal approximation for large df
        if df2 > 30 {
            let z = sqrt(2 * f * df1 / df2) - sqrt(2 * df1 - 1)
            return 1 - normalCDF(z)
        }

        // Simple approximation for smaller df
        let x = df2 / (df2 + df1 * f)
        return incompleteBeta(a: df2 / 2, b: df1 / 2, x: x)
    }

    // MARK: - Confounding Control

    /// Stratified analysis: calculate correlation separately for different conditions
    func stratifiedCorrelation(
        habitDates: [Date],
        metricData: [(date: Date, value: Double)],
        strataAssignment: [Date: String]  // e.g., "workout_day" vs "rest_day"
    ) -> [String: CorrelationResult] {
        var results: [String: CorrelationResult] = [:]
        let calendar = Calendar.current

        // Group data by strata
        var strataData: [String: (x: [Double], y: [Double])] = [:]
        let habitDateSet = Set(habitDates.map { calendar.startOfDay(for: $0) })

        for metric in metricData {
            let metricDate = calendar.startOfDay(for: metric.date)
            let stratum = strataAssignment[metricDate] ?? "unknown"

            if strataData[stratum] == nil {
                strataData[stratum] = (x: [], y: [])
            }

            let habitDone = habitDateSet.contains(metricDate)
            strataData[stratum]?.x.append(habitDone ? 1.0 : 0.0)
            strataData[stratum]?.y.append(metric.value)
        }

        // Calculate correlation for each stratum
        for (stratum, data) in strataData {
            if let result = pearsonCorrelation(data.x, data.y) {
                results[stratum] = result
            }
        }

        return results
    }

    // MARK: - Helper Methods

    /// Calculate mean
    func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Calculate standard deviation
    func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let avg = mean(values)
        let variance = values.map { pow($0 - avg, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }

    /// Calculate percentage change with proper handling
    func percentageChange(baseline: Double, new: Double) -> Double {
        guard baseline != 0 else { return 0 }
        return ((new - baseline) / abs(baseline)) * 100
    }
}
