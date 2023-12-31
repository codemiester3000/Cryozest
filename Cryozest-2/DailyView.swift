import SwiftUI

struct DailyView: View {
    var body: some View {
        ScrollView {
            RecoveryCardView(model: RecoveryGraphModel())
            
            RecoveryGraphView(model: RecoveryGraphModel())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

class RecoveryGraphModel: ObservableObject {
    
    @Published var previousNightSleepDuration: String? = nil
    
    
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
    @Published var lastKnownHRVTime: String? = nil // Add this property
    
    
    
    
    var hrvReadings: [Date: Int] = [:]
    
    func getClosestHRVReading(for date: Date) -> Int? {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date) // Start of the given date
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)! // Start of the next day
        
        let sortedDates = hrvReadings.keys.filter { $0 >= startDate && $0 < endDate }.sorted().reversed()
        for readingDate in sortedDates {
            return hrvReadings[readingDate]
        }
        return nil
    }
    
    
    private func formatSleepDuration(_ duration: TimeInterval) -> String {
        let hours = duration / 3600  // Convert seconds to hours
        return String(format: "%.1f", hours)
    }
    
    
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
        
        HealthKitManager.shared.fetchSleepDurationForPreviousNight() { sleepDuration in
            DispatchQueue.main.async {
                if let sleepDuration = sleepDuration {
                    self.previousNightSleepDuration = self.formatSleepDuration(sleepDuration)
                } else {
                    self.previousNightSleepDuration = nil
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
        let today = calendar.startOfDay(for: Date())
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.insert(date, at: 0) // Insert at the beginning to reverse the order
            }
        }
        // At this point, 'dates' contains the last seven days including today,
        // each normalized to start at midnight
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
            DispatchQueue.main.async {
                if let avgHrv = avgHrv {
                    self.hrvReadings[date] = Int(avgHrv)
                }
                group.leave()
            }
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
        let last7Days = getLastSevenDaysDates()  // Assuming this returns [Date]
        var temporaryScores: [Date: Int] = [:]
        let group = DispatchGroup()
        
        for date in last7Days {
            group.enter()
            
            performMultipleHealthKitOperations(date: date) { avgHrvLast10days, avgHrvForDate, avgHeartRate30day, avgRestingHeartRateForDay in
                
                // Now calling calculateRecoveryScore with the correct parameters
                let score = self.calculateRecoveryScore(
                    date: date,
                    avgHrvLast10days: avgHrvLast10days,
                    avgHrvForDate: avgHrvForDate,
                    avgHeartRate30day: avgHeartRate30day,
                    avgRestingHeartRateForDay: avgRestingHeartRateForDay
                )
                
                DispatchQueue.main.async {
                    temporaryScores[date] = score
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // Once all data is fetched and processed, update recoveryScores
            self.recoveryScores = last7Days.compactMap { temporaryScores[$0] }
            let sortedDates = self.getLastSevenDaysDates().sorted()
            self.recoveryScores = sortedDates.compactMap { temporaryScores[$0] }
        }
    }
    
    func calculateRecoveryScore(date: Date, avgHrvLast10days: Int?, avgHrvForDate: Int?, avgHeartRate30day: Int?, avgRestingHeartRateForDay: Int?) -> Int {
        guard let avgHrvLast10days = avgHrvLast10days, avgHrvLast10days > 0,
              let avgHeartRate30day = avgHeartRate30day, avgHeartRate30day > 0,
              let avgRestingHeartRateForDay = avgRestingHeartRateForDay else {
            return 0
        }
        
        // Use avgHrvForDate if available; otherwise, use the closest available HRV reading
        let effectiveAvgHrv = avgHrvForDate ?? getClosestHRVReading(for: date)
        
        guard let safeAvgHrvForDate = effectiveAvgHrv else {
            return 0
        }
        
        let scaledHrvRatio = (Double(safeAvgHrvForDate) / Double(avgHrvLast10days)) / 1.33
        let scaledHeartRateRatio = (Double(avgRestingHeartRateForDay) / Double(avgHeartRate30day)) / 1.25
        
        let recoveryScore = 0.8 * scaledHrvRatio + 0.2 * scaledHeartRateRatio
        let normalizedScore = min(max(Int(recoveryScore * 100), 0), 100)
        
        return normalizedScore
    }
}


struct RecoveryGraphView: View {
    @ObservedObject var model: RecoveryGraphModel
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Recovery Per Day")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical)
                
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
                .padding(.horizontal)
            }
        }
        .frame(height: 200) // Adjust the height as needed
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
                //                Text("Daily Summary")
                //                    .font(.title2)
                //                    .fontWeight(.semibold)
                //                    .foregroundColor(.white)
                //                    .padding(.vertical, 20)
                //
                //                // Ready to Train Circle
                //                ZStack {
                //                    Circle()
                //                        .stroke(lineWidth: 10)
                //                        .foregroundColor(Color(.systemGreen).opacity(0.5)) // Lighter shade of green
                //
                //                    Circle()
                //                        .trim(from: 0, to: 0.99) // Adjust for actual percentage
                //                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                //                        .foregroundColor(Color(.systemGreen)) // Striking shade of green
                //                        .rotationEffect(.degrees(-90)) // Start from the top
                //
                //                    VStack {
                //                        Text("Ready to Train")
                //                            .font(.headline) // Increase the font size for "Ready to Train"
                //                            .fontWeight(.bold)
                //                            .multilineTextAlignment(.center)
                //                            .foregroundColor(.white)
                //
                //                        Text("\(model.recoveryScores.last ?? 0)%")
                //                            .font(.largeTitle) // Increase the font size for the percentage number
                //                            .fontWeight(.bold)
                //                            .multilineTextAlignment(.center)
                //                            .foregroundColor(.white)
                //                    }
                //                    .padding(10) // Add some padding for spacing between the two lines
                //                }
                //                .frame(width: 150, height: 150)
                
                HStack {
                    Text("Daily Summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.top, -30)
                    
                    Spacer() // Adding a spacer for separation
                    
                    // Ready to Train Circle - Made smaller
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8) // Slightly thinner stroke
                            .foregroundColor(Color(.systemGreen).opacity(0.5))
                        
                        Circle()
                            .trim(from: 0, to: 0.99)
                            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .foregroundColor(Color(.systemGreen))
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("Ready to Train")
                                .font(.system(size: 10))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                            
                            Text("\(model.recoveryScores.last ?? 0)%")
                                .font(.title3) // Smaller font size
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                        .padding(8) // Reduced padding
                    }
                    .frame(width: 120, height: 120) // Smaller frame size
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
                
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
                
                // Horizontal Stack for Grid Items
                HStack(spacing: 10) {
                    GridItemView(
                        title: "Sleep",
                        value: model.previousNightSleepDuration ?? "N/A",
                        unit: "hrs"
                    )
                    
                    GridItemView(
                        title: "HRV",
                        value: "\(model.lastKnownHRV)",
                        unit: "ms"
                    )
                    GridItemView(
                        title: "RHR",
                        value: "\(model.mostRecentRestingHeartRate ?? 0)",
                        unit: "bpm"
                    )
                }
                .padding(.all, 10)
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            //.background(Color.black.opacity(0.0))
            //.cornerRadius(10)
            .padding(.horizontal)
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
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 2)
            
            HStack(alignment: .lastTextBaseline) {
                Text(value)
                    .font(.system(size: 22)) // Custom font size
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.leading, 1) // Reduced padding, adjust as needed
            }
        }
        .padding(.all, 8)
        .frame(width: 100, height: 100)
        .background(Color.black)
        .cornerRadius(8)
        .shadow(radius: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red, lineWidth: 1) // Red ring with 1-point line width
        )
    }
}




