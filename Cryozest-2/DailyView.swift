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
        }
    }
    @Published var avgHrvDuringSleep60Days: Int? {
        didSet {
            calculateHrvPercentage()
        }
    }
    @Published var hrvSleepPercentage: Int?
    
    // MARK -- Heart Rate variables
    @Published var mostRecentRestingHeartRate: Int? {
        didSet {
            calculateRestingHeartRatePercentage()
        }
    }
    @Published var avgRestingHeartRate60Days: Int? {
        didSet {
            calculateRestingHeartRatePercentage()
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
    @Published var lastKnownHRV: Int = 0  // Add a default value or make it optional
    
    
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
        
        HealthKitManager.shared.fetchLastKnownHRV(before: Date()) { lastHrv in
            DispatchQueue.main.async {
                if let lastHrv = lastHrv {
                    self.lastKnownHRV = Int(lastHrv)
                } else {
                    // Handle the case where the last known HRV is not available
                    self.lastKnownHRV = 0  // or handle it differently
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
    
    
    
    func getLastSevenDaysDates() -> [Date] {
        var dates = [Date]()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date()) // Ensure the time is set to midnight
        
        // Generate dates for the last seven days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.insert(date, at: 0) // Insert at the beginning to reverse the order
            }
        }
        return dates
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
        
        var temporaryScores: [Date: Int] = [:]
        let group = DispatchGroup()
        
        for (index, dayOfWeek) in last7Days.enumerated() {
            if let date = calendar.date(byAdding: .day, value: -index, to: today) {
                group.enter()
                
                performMultipleHealthKitOperations(date: date) { avgHrvLast10days, avgHrvForDate, avgHeartRate30day, avgRestingHeartRateForDay in
                                    
                    let score = self.calculateRecoveryScore(
                        avgHrvLast10days: avgHrvLast10days,
                        avgHrvForDate: avgHrvForDate,
                        lastKnownHrv: self.lastKnownHRV,  // Pass the last known HRV here
                        avgHeartRate30day: avgHeartRate30day,
                        avgRestingHeartRateForDay: avgRestingHeartRateForDay
                    )
                    
                    DispatchQueue.main.async {
                        temporaryScores[date] = score
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            let sortedDates = self.getLastSevenDaysDates().sorted()
            self.recoveryScores = sortedDates.compactMap { temporaryScores[$0] }
        }
    }
    
    func calculateRecoveryScore(avgHrvLast10days: Int?, avgHrvForDate: Int?, lastKnownHrv: Int, avgHeartRate30day: Int?, avgRestingHeartRateForDay: Int?) -> Int {
        // Ensure that some of the required data is available and valid
        guard let avgHrvLast10days = avgHrvLast10days, avgHrvLast10days > 0,
              let avgRestingHeartRateForDay = avgRestingHeartRateForDay,
              let avgHeartRate30day = avgHeartRate30day, avgHeartRate30day > 0 else {
            return 0
        }
        
        // Use the last known HRV as a fallback for avgHrvForDate if it's nil
        let safeAvgHrvForDate = avgHrvForDate ?? lastKnownHrv
        
        // Apply the adjusted formula
        let scaledHrvRatio = (Double(safeAvgHrvForDate) / Double(avgHrvLast10days)) / 1.33
        let scaledHeartRateRatio = (Double(avgRestingHeartRateForDay) / Double(avgHeartRate30day)) / 1.25
        
        let recoveryScore = 0.8 * scaledHrvRatio + 0.2 * scaledHeartRateRatio
        
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
        ScrollView {
            VStack {
                        Text("Daily Summary")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.top, 20)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    GridItemView(
                        title: "Recovery",
                        value: "\(model.recoveryScores.last ?? 0)", // Pass only the number
                        unit: "%" // Pass the unit separately
                    )
                    GridItemView(
                        title: "HRV",
                        value: "\(model.lastKnownHRV)", // Pass only the number
                        unit: "ms" // Pass the unit separately
                    )
                    GridItemView(
                        title: "RHR",
                        value: "\(model.mostRecentRestingHeartRate ?? 0)", // Pass only the number
                        unit: "bpm" // Pass the unit separately
                    )
                    // ... Add more grid items if needed
                }
                .padding(.all, 10)

                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
            .padding(.horizontal)


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


struct GridItemView: View {
    var title: String
    var value: String
    var unit: String

    var body: some View {
        VStack {
            Text(title)
                .font(.headline) // You can adjust the font size as needed
                .foregroundColor(.white)
                .padding(.bottom, 2) // Reduce the bottom padding to bring title closer to the number

            HStack(alignment: .lastTextBaseline) { // Align the baseline of the text
                Text(value)
                    .font(.largeTitle) // You can adjust the font size as needed
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(unit)
                    .font(.footnote) // Smaller font size for the unit
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.leading, 2) // Space between the number and the unit
            }

            // Eliminate excess space by removing Spacers
        }
        .padding(.all, 8) // Reduced padding within each grid item
        .frame(width: 100, height: 100) // Smaller frame for the grid item
        .background(Color.black)
        .cornerRadius(8)
        .shadow(radius: 3)
    }
}






                
