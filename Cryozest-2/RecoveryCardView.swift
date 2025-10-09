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
            Spacer(minLength: 20)
            
            VStack(alignment: .leading) {
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Recovery")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .foregroundColor(Color(.systemGreen).opacity(0.5))
                        let progress = Double(model.recoveryScores.last ?? 0) / 100.0
                        let progressColor = Color(red: 1.0 - progress, green: progress, blue: 0)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progress)) // Use the progress value here
                            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .foregroundColor(progressColor)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("Ready to Train")
                                .font(.system(size: 10))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                            
                            Text("\(model.recoveryScores.last ?? 0)%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 120, height: 120)
                    
                }
                .padding(.horizontal, 22)
                
                // Metrics and paragraph
                VStack {
                    HStack {
                        MetricView(
                            label: model.avgHrvDuringSleep != nil ? "\(model.avgHrvDuringSleep!) ms" : "N/A",
                            symbolName: "heart.fill",
                            change: "\(model.hrvSleepPercentage ?? 0)% (\(model.avgHrvDuringSleep60Days ?? 0))",
                            arrowUp: model.avgHrvDuringSleep ?? 0 > model.avgHrvDuringSleep60Days ?? 0,
                            isGreen: model.avgHrvDuringSleep ?? 0 > model.avgHrvDuringSleep60Days ?? 0
                        )
                        
                        Spacer()
                        
                        MetricView(
                            label: "\(model.mostRecentRestingHeartRate ?? 0) bpm",
                            symbolName: "waveform.path.ecg",
                            change: "\(model.restingHeartRatePercentage ?? 0)% (\(model.avgRestingHeartRate60Days ?? 0))",
                            arrowUp: model.mostRecentRestingHeartRate ?? 0 > model.avgRestingHeartRate60Days ?? 0,
                            isGreen: model.mostRecentRestingHeartRate ?? 0 < model.avgRestingHeartRate60Days ?? 0
                        )
                        
                    }
                    .padding(.bottom, 5)
                    
                    RecoveryExplanation(model: model)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 32)
                    
                    Spacer() // Add a Spacer between RecoveryExplanation and RecoveryGraphView
                    
                    RecoveryGraphView(model: model)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 32)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
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
        VStack {
            if (model.avgHrvDuringSleep ?? 0) == 0 || (model.mostRecentRestingHeartRate ?? 0) == 0 {
                Text("Wear your Apple Watch to get recovery information")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            else {
                Text("Recovery is based on your average HRV during sleep of ")
                    .font(.system(size: 16))
                    .foregroundColor(.white) +
                Text("\(model.avgHrvDuringSleep ?? 0) ms ")
                    .font(.system(size: 17))
                    .foregroundColor(.green)
                    .fontWeight(.bold) +
                Text("which is \(abs(model.hrvSleepPercentage ?? 0))% \(model.hrvSleepPercentage ?? 0 < 0 ? "lower" : "higher") than your 60 day average of \(model.avgHrvDuringSleep60Days ?? 0) ms and your average  resting heart rate during sleep of ")
                    .font(.system(size: 16))
                    .foregroundColor(.white) +
                Text("\(model.mostRecentRestingHeartRate ?? 0) bpm ")
                    .font(.system(size: 17))
                    .foregroundColor(.green)
                    .fontWeight(.bold) +
                Text("which is \(abs(model.restingHeartRatePercentage ?? 0))% \(model.restingHeartRatePercentage ?? 0 < 0 ? "lower" : "higher") than your 60 day average of \(model.avgRestingHeartRate60Days ?? 0) bpm.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct MetricView: View {
    let label: String
    let symbolName: String
    let change: String
    let arrowUp: Bool
    let isGreen: Bool
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: symbolName)
                    .foregroundColor(.gray)
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            HStack {
                Text(change)
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(0.7)
                Text(arrowUp ? "↑" : "↓")
                    .font(.footnote)
                    .foregroundColor(isGreen ? .green : .red)
            }
            .padding(.leading, 4)
        }
    }
}

struct RecoveryGraphView: View {
    @ObservedObject var model: RecoveryGraphModel
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Recovery Per Day")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(zip(model.getLastSevenDays(), model.recoveryScores)), id: \.0) { (day, percentage) in
                    VStack {
                        Text("\(percentage)%")
                            .font(.caption)
                            .foregroundColor(.white)
                        Rectangle()
                            .fill(getColor(forPercentage: percentage))
                            .frame(width: 40, height: CGFloat(percentage))
                            .cornerRadius(5)
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            HStack {
                Text("Weekly Average: \(model.weeklyAverage)%")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.leading, 18)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 32)
    }
    
    // Function to get color based on percentage
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
