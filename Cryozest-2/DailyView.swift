import SwiftUI

struct DailyView: View {
    var body: some View {
        ScrollView {
            RecoveryCardView(model: RecoveryGraphModel())
            
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
    
    @Published var recoveryScores = [Int]() {
        didSet {
            let sum = self.recoveryScores.reduce(0, +) // Sums up all elements in the array
            self.weeklyAverage = self.recoveryScores.isEmpty ? 0 : sum / self.recoveryScores.count
        }
    }

    
    @Published var weeklyAverage: Int = 0
    
    init() {
        self.getLastSevenDaysOfRecoveryScores()
        
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
        
        HealthKitManager.shared.fetchNDayAvgRestingHeartRate(numDays: 60) { restingHeartRate60days in
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
    
    func performMultipleHealthKitOperations(date: Date, completion: @escaping (Int?, Int?, Int?, Int?) -> Void) {
        let group = DispatchGroup()
        
        var avgHrvLast10days: Int? = nil
        var avgHrvForDate: Int? = nil
        var avgHeartRate30day: Int? = nil
        var avgRestingHeartRateForDay: Int? = nil
        
        group.enter()
        HealthKitManager.shared.fetchAvgHRVForLastDays(numberOfDays: 10) { avgHrv in
            if let avgHrv = avgHrv {
                avgHrvLast10days = Int(avgHrv)
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgHRVDuringSleepForNightEndingOn(date: date) { avgHrv in
            if let avgHrv = avgHrv {
                avgHrvForDate = Int(avgHrv)
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchNDayAvgRestingHeartRate(numDays: 30) { restingHeartRate in
            if let restingHeartRate = restingHeartRate {
                avgHeartRate30day = restingHeartRate
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: [date]) { restingHeartRate in
            if let heartRate = restingHeartRate {
                avgRestingHeartRateForDay = Int(heartRate)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            // All tasks are complete, call completion with the fetched data
            completion(avgHrvLast10days, avgHrvForDate, avgHeartRate30day, avgRestingHeartRateForDay)
        }
    }
    
    func getLastSevenDaysOfRecoveryScores() {
        let last7Days = getLastSevenDays() // ["SUN", "SAT", "FRI", "THU", "WED", "TUE", "MON"]
        //var newRecoveryScores = [Int]()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        self.recoveryScores = []
        
        for (index, dayOfWeek) in last7Days.enumerated() {
            if let date = calendar.date(byAdding: .day, value: -index, to: today) {
                
                performMultipleHealthKitOperations(date: date) { avgHrvLast10days, avgHrvForDate, avgHeartRate30day, avgRestingHeartRateForDay in
                    print("\n")
                    print("avgHrvLast10days: ", avgHrvLast10days)
                    print("avgHeartRate30day: ", avgHeartRate30day)
                    print("avgRestingHeartRateForDay: ", avgRestingHeartRateForDay)
                    print("avgHrvForDate: ", avgHrvForDate)
                    print("\n")
                    
                    self.recoveryScores.append(self.calculateRecoveryScore(avgHrvLast10days: avgHrvLast10days, avgHrvForDate: avgHrvForDate, avgHeartRate30day: avgHeartRate30day, avgRestingHeartRateForDay: avgRestingHeartRateForDay))
                }
            }
        }
    }
    
    func calculateRecoveryScore(avgHrvLast10days: Int?, avgHrvForDate: Int?, avgHeartRate30day: Int?, avgRestingHeartRateForDay: Int?) -> Int {
        // Ensure all required data is available
        guard let avgHrvForDate = avgHrvForDate, let avgHrvLast10days = avgHrvLast10days, avgHrvLast10days > 0,
              let avgRestingHeartRateForDay = avgRestingHeartRateForDay, let avgHeartRate30day = avgHeartRate30day, avgHeartRate30day > 0 else {
            return 0
        }
        
        // Apply the new formula
        let hrvRatio = Double(avgHrvForDate) / Double(avgHrvLast10days)
        let heartRateRatio = Double(avgRestingHeartRateForDay) / Double(avgHeartRate30day)
        
        let recoveryScore = 0.8 * hrvRatio + 0.2 * heartRateRatio
        
        // Normalize the score to be between 0 and 100
        let normalizedScore = min(max(Int(recoveryScore * 100), 0), 100)
        
        return normalizedScore
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
                    Text("Weekly Average: \(model.weeklyAverage)%") // Update this value based on actual data if needed
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
}

struct RecoveryCardView: View {
    @ObservedObject var model: RecoveryGraphModel
    
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
                    
                    Text("Ready to Train\n\(model.recoveryScores.last ?? 0)%")
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
