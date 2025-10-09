import SwiftUI
import CoreData

struct RecoveryCardView: View {
    @ObservedObject var model: RecoveryGraphModel
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with ring
                HStack(alignment: .top, spacing: 16) {
                    Text("Readiness to Train")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 8)
                            .frame(width: 100, height: 100)

                        let progress = Double(model.recoveryScores.last ?? 0) / 100.0
                        let progressColor = Color(red: 1.0 - progress, green: progress, blue: 0)

                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(progressColor, lineWidth: 8)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 100, height: 100)

                        VStack(spacing: 2) {
                            Text("\(model.recoveryScores.last ?? 0)%")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Ready")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Key metrics
                HStack(spacing: 12) {
                    MetricView(
                        label: model.avgHrvDuringSleep != nil ? "\(model.avgHrvDuringSleep!) ms" : "N/A",
                        symbolName: "heart.fill",
                        change: "\(model.hrvSleepPercentage ?? 0)% (\(model.avgHrvDuringSleep60Days ?? 0))",
                        arrowUp: model.avgHrvDuringSleep ?? 0 > model.avgHrvDuringSleep60Days ?? 0,
                        isGreen: model.avgHrvDuringSleep ?? 0 > model.avgHrvDuringSleep60Days ?? 0
                    )

                    MetricView(
                        label: "\(model.mostRecentRestingHeartRate ?? 0) bpm",
                        symbolName: "waveform.path.ecg",
                        change: "\(model.restingHeartRatePercentage ?? 0)% (\(model.avgRestingHeartRate60Days ?? 0))",
                        arrowUp: model.mostRecentRestingHeartRate ?? 0 > model.avgRestingHeartRate60Days ?? 0,
                        isGreen: model.mostRecentRestingHeartRate ?? 0 < model.avgRestingHeartRate60Days ?? 0
                    )
                }
                .padding(.horizontal, 20)

                // Explanation card
                RecoveryExplanation(model: model)
                    .padding(.horizontal, 20)

                // Recovery graph
                RecoveryGraphView(model: model)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct RecoveryExplanation: View {
    @ObservedObject var model: RecoveryGraphModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if (model.avgHrvDuringSleep ?? 0) == 0 || (model.mostRecentRestingHeartRate ?? 0) == 0 {
                Text("Wear your Apple Watch to get recovery information")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Recovery is based on your average HRV during sleep of ")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8)) +
                Text("\(model.avgHrvDuringSleep ?? 0) ms")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.green) +
                Text(" which is \(abs(model.hrvSleepPercentage ?? 0))% \(model.hrvSleepPercentage ?? 0 < 0 ? "lower" : "higher") than your 60 day average of \(model.avgHrvDuringSleep60Days ?? 0) ms and your average resting heart rate during sleep of ")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8)) +
                Text("\(model.mostRecentRestingHeartRate ?? 0) bpm")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.green) +
                Text(" which is \(abs(model.restingHeartRatePercentage ?? 0))% \(model.restingHeartRatePercentage ?? 0 < 0 ? "lower" : "higher") than your 60 day average of \(model.avgRestingHeartRate60Days ?? 0) bpm.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

struct MetricView: View {
    let label: String
    let symbolName: String
    let change: String
    let arrowUp: Bool
    let isGreen: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isGreen ? .green : .red)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill((isGreen ? Color.green : Color.red).opacity(0.2))
                )

            // Main value
            Text(label)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // Change indicator
            HStack(spacing: 4) {
                Image(systemName: arrowUp ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isGreen ? .green : .red)
                Text(change)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke((isGreen ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct RecoveryGraphView: View {
    @ObservedObject var model: RecoveryGraphModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("7-Day Recovery Trend")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("Avg: \(model.weeklyAverage)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(zip(model.getLastSevenDays(), model.recoveryScores)), id: \.0) { (day, percentage) in
                    VStack(spacing: 6) {
                        Text("\(percentage)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        getColor(forPercentage: percentage),
                                        getColor(forPercentage: percentage).opacity(0.7)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 36, height: max(CGFloat(percentage) * 1.2, 10))

                        Text(day)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(height: 140)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    func getColor(forPercentage percentage: Int) -> Color {
        switch percentage {
        case let x where x > 50:
            return .green
        case let x where x > 30:
            return .yellow
        default:
            return .red
        }
    }
}
