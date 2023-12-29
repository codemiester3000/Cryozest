import SwiftUI

struct DailyView: View {
    var body: some View {
        ScrollView {
            RecoveryCardView(model: RecoveryCardModel())
            
            RecoveryGraphView(model: RecoveryGraphModel())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

class RecoveryGraphModel: ObservableObject {
    
    func getLastSevenDays() -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE" // Format for day of the week
        
        var daysArray = [String]()
        
        // Generate days from today to the past six days
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                let day = dateFormatter.string(from: date).uppercased()
                daysArray.insert(day, at: 0) // Insert at the beginning to reverse the order
            }
        }
        return daysArray
    }
    
    func calculateRecoveryScore(hrvPercentage: Int, restingHRPercentage: Int) -> Int {
        var score = 0
        
        score += max(0, hrvPercentage)
        
        score += max(0, -restingHRPercentage)
        
        let normalizedScore = min(max(score, 0), 100)
        
        return normalizedScore
    }
    
    func getLastSevenDaysOfRecoveryScores() -> [Int] {
        let last7Days = getLastSevenDays()
        var recoveryScores = [Int]()
        
        for day in last7Days {
            // Retrieve or calculate the recovery score for each day.
            // This is a placeholder. Replace with your actual data retrieval logic.
            
            // TODO: Make healthkit requests
            
            let hrvPercentage = getHRVPercentage(forDay: day)
            let restingHRPercentage = getRestingHRPercentage(forDay: day)
            
            let score = calculateRecoveryScore(hrvPercentage: hrvPercentage, restingHRPercentage: restingHRPercentage)
            recoveryScores.append(score)
        }
        
        return recoveryScores
    }
    
    // Placeholder function for HRV percentage retrieval
    private func getHRVPercentage(forDay day: String) -> Int {
        // Logic to retrieve HRV percentage for the given day.
        // Return a dummy value for now
        return Int.random(in: 30...100)
    }
    
    // Placeholder function for Resting Heart Rate percentage retrieval
    private func getRestingHRPercentage(forDay day: String) -> Int {
        // Logic to retrieve resting heart rate percentage for the given day.
        // Return a dummy value for now
        return Int.random(in: -50...50)
    }
}

struct RecoveryGraphView: View {
    @ObservedObject var model: RecoveryGraphModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.8) // Card background color
                .cornerRadius(10)
            
            VStack {
                HStack {
                    Text("Recovery Per Day")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
                
                HStack(alignment: .bottom) {
                    ForEach(Array(zip(model.getLastSevenDays(), model.getLastSevenDaysOfRecoveryScores())), id: \.0) { (day, percentage) in
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
                    Text("Weekly Average: \(calculateWeeklyAverage())%") // Update this value based on actual data if needed
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.top)
            }
        }
        .frame(height: 300) // Adjust the height as needed
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
    
    // Function to calculate weekly average
    func calculateWeeklyAverage() -> Int {
        let scores = model.getLastSevenDaysOfRecoveryScores()
        let total = scores.reduce(0, +)
        return total / scores.count
    }
}


class RecoveryCardModel: ObservableObject {
    
    // MARK -- HRV variables
    @Published var avgHrvDuringSleep: Int? {
        didSet {
            calculateHrvPercentage()
            calculateRecoveryScore()
        }
    }
    @Published var avgHrvDuringSleep60Days: Int? {
        didSet {
            calculateHrvPercentage()
            calculateRecoveryScore()
        }
    }
    @Published var hrvSleepPercentage: Int?
    
    // MARK -- Heart Rate variables
    @Published var mostRecentRestingHeartRate: Int? {
        didSet {
            calculateRestingHeartRatePercentage()
            calculateRecoveryScore()
        }
    }
    @Published var avgRestingHeartRate60Days: Int? {
        didSet {
            calculateRestingHeartRatePercentage()
            calculateRecoveryScore()
        }
    }
    @Published var restingHeartRatePercentage: Int?
    
    @Published var recoveryScore: Int?
    
    init() {
        HealthKitManager.shared.fetchAvgHRVDuringSleepForPreviousNight() { hrv in
            DispatchQueue.main.async {
                if let hrv = hrv {
                    self.avgHrvDuringSleep = Int(hrv)
                } else {
                    self.avgHrvDuringSleep = nil
                }
            }
        }
        
        HealthKitManager.shared.fetchAvgHRVDuring60DaysSleep() { hrv in
            DispatchQueue.main.async {
                if let hrv = hrv {
                    self.avgHrvDuringSleep60Days = Int(hrv)
                } else {
                    self.avgHrvDuringSleep60Days = nil
                }
            }
        }
        
        HealthKitManager.shared.fetchMostRecentRestingHeartRate() { restingHeartRate in
            DispatchQueue.main.async {
                if let restingHeartRate = restingHeartRate {
                    self.mostRecentRestingHeartRate = restingHeartRate
                } else {
                    self.mostRecentRestingHeartRate = nil
                }
            }
        }
        
        HealthKitManager.shared.fetch60DayAvgRestingHeartRate() { restingHeartRate60days in
            DispatchQueue.main.async {
                if let restingHeartRate = restingHeartRate60days {
                    self.avgRestingHeartRate60Days = restingHeartRate
                } else {
                    self.avgRestingHeartRate60Days = nil
                }
            }
        }
    }
    
    private func calculateRecoveryScore() {
        var score = 0
        
        if let hrvPercentage = hrvSleepPercentage {
            score += max(0, hrvPercentage)
        }
        
        if let restingHRPercentage = restingHeartRatePercentage {
            score += max(0, -restingHRPercentage)
        }
        
        let normalizedScore = min(max(score, 0), 100)
        
        recoveryScore = normalizedScore
    }
    
    private func calculateHrvPercentage() {
        if let avgSleep = avgHrvDuringSleep, let avg60Days = avgHrvDuringSleep60Days, avg60Days > 0 {
            let percentage = Double(avgSleep - avg60Days) / Double(avg60Days) * 100
            hrvSleepPercentage = Int(percentage.rounded())
        } else {
            hrvSleepPercentage = nil
        }
    }
    
    private func calculateRestingHeartRatePercentage() {
        if let mostRecentHr = mostRecentRestingHeartRate, let avg60Days = avgRestingHeartRate60Days, avg60Days > 0 {
            let percentage = Double(mostRecentHr - avg60Days) / Double(avg60Days) * 100
            restingHeartRatePercentage = Int(percentage.rounded())
        } else {
            restingHeartRatePercentage = nil
        }
    }
}


struct RecoveryCardView: View {
    @ObservedObject var model: RecoveryCardModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .cornerRadius(10)
            
            VStack(spacing: 10) {
                // Ready to Train Circle
                ZStack {
                    Circle()
                        .stroke(lineWidth: 10)
                        .foregroundColor(.green)
                        .opacity(0.2)
                    
                    Circle()
                        .trim(from: 0, to: 0.99) // Adjust for actual percentage
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .foregroundColor(.green)
                        .rotationEffect(.degrees(-90)) // Start from the top
                    
                    Text("Ready to Train\n\(model.recoveryScore ?? 0)%")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                }
                .frame(width: 150, height: 150)
                
                // Metrics and paragraph
                VStack {
                    HStack {
                        MetricView(
                            label: model.avgHrvDuringSleep != nil ? "\(model.avgHrvDuringSleep!) ms" : "N/A",
                            symbolName: "heart.fill",
                            change: "\(model.hrvSleepPercentage ?? 0)% (\(model.avgHrvDuringSleep60Days ?? 0)) \(model.hrvSleepPercentage ?? -1 >= 0 ? "↑" : "↓")"
                        )
                        Spacer()
                        
                        MetricView(
                            label: "\(model.mostRecentRestingHeartRate ?? 0) bpm",
                            symbolName: "waveform.path.ecg",
                            change: "\(model.restingHeartRatePercentage ?? 0)% (\(model.avgRestingHeartRate60Days ?? 0)) \(model.restingHeartRatePercentage ?? -1 >= 0 ? "↑" : "↓")"
                        )
                    }
                    .padding(.horizontal)
                    
                    // TODO: COMPLETELY HARDCODED
                    Text("Recovery is based on your average HRV during sleep of \(model.avgHrvDuringSleep ?? 0) ms which is \(abs(model.hrvSleepPercentage ?? 0))% \(model.hrvSleepPercentage ?? 0 < 0 ? "lower" : "higher") than your 60 day average of \(model.avgHrvDuringSleep60Days ?? 0) ms and your most recent resting heart rate of \(model.mostRecentRestingHeartRate ?? 0) bpm which is \(abs(model.restingHeartRatePercentage ?? 0))% lower than your 60 day average of \(model.avgRestingHeartRate60Days ?? 0) bpm.")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
        .frame(height: 400)
    }
}

struct MetricView: View {
    let label: String
    let symbolName: String
    let change: String
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: symbolName)
                    .foregroundColor(.gray)
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Text(change)
                .font(.caption)
                .foregroundColor(.white)
                .opacity(0.7)
        }
    }
}
