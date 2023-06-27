import SwiftUI

class HeartRateViewModel: ObservableObject {
    
    // Average Heart Rate Values
    @Published var avgHeartRateTherapyDays: Double = 0.0
    @Published var avgHeartRateNonTherapyDays: Double = 0.0
    
    // Resting Heart Rate Values
    @Published var restingHeartRateTherapyDays: Double = 0.0
    @Published var restingHeartRateNonTherapyDays: Double = 0.0
    
    // Average Heart Rate during sleep Values
    @Published var avgHeartRateSleepTherapyDays: Double = 0.0
    @Published var avgHeartRateSleepNonTherapyDays: Double = 0.0
    
    // Difference values.
    @Published var restingHeartRateDifference: Double = 0.0
    @Published var avgHeartRateDifference: Double = 0.0
    @Published var avgHeartRateSleepDifference: Double = 0.0
    
    // Whether to show the ghost card while fetching HealthKit data.
    @Published var isLoading: Bool = true
    
    @Published var timeFrame: TimeFrame {
        didSet {
            if oldValue != timeFrame {
                fetchHeartRates()
            }
        }
    }
    
    @Published var therapyType: TherapyType {
        didSet {
            if oldValue != therapyType {
                fetchHeartRates()
            }
        }
    }
    var sessions: FetchedResults<TherapySessionEntity>
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.therapyType = therapyType
        self.timeFrame = timeFrame
        self.sessions = sessions
        
        fetchHeartRates()
    }
    
    func fetchHeartRates() {
        self.isLoading = true
        let group = DispatchGroup()
        
        fetchrestingHeartRateTherapyDays(group: group)
        fetchrestingHeartRateNonTherapyDays(group: group)
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    private func calculateRestingHRDifference() {
        if restingHeartRateTherapyDays != 0 {
            let differenceValue = (restingHeartRateTherapyDays - restingHeartRateNonTherapyDays) / restingHeartRateNonTherapyDays * 100
            restingHeartRateDifference = differenceValue
        } else {
            // print("Resting heart rate on therapy days is zero, can't calculate difference.")
        }
    }
    
    private func calculateAvgHRDifference() {
        if avgHeartRateTherapyDays != 0 {
            let differenceValue = (avgHeartRateTherapyDays - avgHeartRateNonTherapyDays) / avgHeartRateNonTherapyDays * 100
            avgHeartRateDifference = differenceValue
        } else {
            // print("Resting heart rate on therapy days is zero, can't calculate difference.")
        }
    }
    
    private func calculateAvgHRSleepDifference() {
        if avgHeartRateSleepTherapyDays != 0 {
            let differenceValue = (avgHeartRateSleepTherapyDays - avgHeartRateSleepNonTherapyDays) / avgHeartRateSleepNonTherapyDays * 100
            avgHeartRateSleepDifference = differenceValue
        } else {
            // print("Average heart rate during sleep on therapy days is zero, can't calculate difference.")
        }
    }
    
    private func fetchrestingHeartRateTherapyDays(group: DispatchGroup) {
        let completedSessionDates = sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
        
//        group.enter()
//        HealthKitManager.shared.fetchAvgHeartRateDuringSleepForDays(days: completedSessionDates) { avgHeartRateSleep in
//            if let avgHeartRateSleep = avgHeartRateSleep {
//                self.avgHeartRateSleepTherapyDays = avgHeartRateSleep
//                self.calculateAvgHRSleepDifference()
//            } else {
//                print("Failed to fetch average heart rate during sleep on therapy days.")
//            }
//            group.leave()
//        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.restingHeartRateTherapyDays = avgHeartRateExcluding
                self.calculateRestingHRDifference()
            } else {
                // print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.avgHeartRateTherapyDays = avgHeartRateExcluding
                self.calculateAvgHRDifference()
            } else {
                // print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
    }
    
    private func fetchrestingHeartRateNonTherapyDays(group: DispatchGroup) {
        let completedSessionDates = sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
        
        // Get the dates for the last month.
        let calendar = Calendar.current
        let dateOneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        
        let numberOfDays: Int
        switch timeFrame {
        case .week:
            numberOfDays = 7
        case .month:
            numberOfDays = 30
        case .allTime:
            numberOfDays = 365
        }
        
        // Exclude completedSessionDates from the last month's dates.
        var lastMonthDates = [Date]()
        for day in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: -day, to: Date()),
               !completedSessionDates.contains(date),
               date >= dateOneMonthAgo {
                lastMonthDates.append(date)
            }
        }
        
//        group.enter()
//        HealthKitManager.shared.fetchAvgHeartRateDuringSleepForDays(days: lastMonthDates) { fetchedAvgHeartRateSleep in
//            if let fetchedAvgHeartRateSleep = fetchedAvgHeartRateSleep {
//                self.avgHeartRateSleepNonTherapyDays = fetchedAvgHeartRateSleep
//                self.calculateAvgHRSleepDifference()
//            } else {
//                print("Failed to fetch average heart rate during sleep on non-therapy days.")
//            }
//            group.leave()
//        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: lastMonthDates) { fetchedAvgHeartRateExcluding in
            if let fetchedAvgHeartRateExcluding = fetchedAvgHeartRateExcluding {
                self.restingHeartRateNonTherapyDays = fetchedAvgHeartRateExcluding
                self.calculateRestingHRDifference()
            } else {
                // print("Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: lastMonthDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.avgHeartRateNonTherapyDays = avgHeartRateExcluding
                self.calculateAvgHRDifference()
            } else {
                // print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
    }
}

extension Double {
    func formatBPM() -> String {
        return self == 0.0 ? "N/A" : String(format: "%.0f bpm", self)
    }
}

struct AvgHeartRateComparisonView: View {
    @ObservedObject var heartRateViewModel: HeartRateViewModel
    
    var body: some View {
        
        if heartRateViewModel.isLoading {
            LoadingView()
        }
        else {
            VStack(alignment: .leading) {
                HStack {
                    Text("Heart Rate")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(heartRateViewModel.timeFrame.displayString())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(heartRateViewModel.therapyType.color)
                        .cornerRadius(8)
                }
                .padding(.bottom, 10)
                
                VStack {
                    
                    if heartRateViewModel.restingHeartRateDifference != 0 || heartRateViewModel.avgHeartRateDifference != 0 {
                        HStack {
                            Text("On \(heartRateViewModel.therapyType.rawValue) days")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold, design: .default))
                            Spacer()
                        }
                    }
                    
                    // Heart Rate differences views.
                    if heartRateViewModel.restingHeartRateDifference != 0 {
                        let differencePercentage = abs(heartRateViewModel.restingHeartRateDifference)
                        let isIncreased = heartRateViewModel.restingHeartRateDifference >= 0
                        HeartRateDifferenceView(differencePercentage: differencePercentage,
                                                therapyType: heartRateViewModel.therapyType.rawValue,
                                                isIncreased: isIncreased,
                                                heartRateType: "RHR")
                    }
                    
                    if heartRateViewModel.avgHeartRateDifference != 0 {
                        let differencePercentage = abs(heartRateViewModel.avgHeartRateDifference)
                        let isIncreased = heartRateViewModel.avgHeartRateDifference >= 0
                        HeartRateDifferenceView(differencePercentage: differencePercentage,
                                                therapyType: heartRateViewModel.therapyType.rawValue,
                                                isIncreased: isIncreased,
                                                heartRateType: "Avg HR")
                    }
                    
                    // Resting Heart Rate View.
                    HStack {
                        Text("Resting Heart Rate")
                            // .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    
                    HStack {
                        Text("On \(heartRateViewModel.therapyType.rawValue) Days")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                        Spacer()
                        Text(heartRateViewModel.restingHeartRateTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5) // Provide some space
                    .background(heartRateViewModel.therapyType.color.opacity(0.2))
                    .cornerRadius(15) // Adds rounded corners
                    
                    HStack {
                        Text("Off Days")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                        Spacer()
                        Text(heartRateViewModel.restingHeartRateNonTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.top, 10)
                
                // Average Heart Rate View.
                VStack {
                    HStack {
                        Text("Avg Heart Rate")
                            //.font(.system(size: 18, weight: .bold, design: .monospaced))
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    
                    HStack {
                        Text("On \(heartRateViewModel.therapyType.rawValue) Days")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                        Spacer()
                        Text(heartRateViewModel.avgHeartRateTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5) // Provide some space
                    .background(heartRateViewModel.therapyType.color.opacity(0.2)) // Different background for therapy days
                    .cornerRadius(15) // Adds rounded corners
                    
                    HStack {
                        Text("Off Days")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                        Spacer()
                        Text(heartRateViewModel.avgHeartRateNonTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.top, 10)
                
                // Resting Heart Rate during sleep view.
//                VStack {
//                    if heartRateViewModel.avgHeartRateSleepDifference != 0 {
//                        let differencePercentage = abs(heartRateViewModel.avgHeartRateSleepDifference)
//                        let isIncreased = heartRateViewModel.avgHeartRateSleepDifference >= 0
//                        HeartRateDifferenceView(differencePercentage: differencePercentage,
//                                                therapyType: heartRateViewModel.therapyType.rawValue,
//                                                isIncreased: isIncreased,
//                                                heartRateType: "Avg HR during Sleep")
//                    }
//
//                    HStack {
//                        Text("HR during Sleep")
//                            .font(.system(size: 18, weight: .bold, design: .monospaced))
//                            .fontWeight(.bold)
//                            .foregroundColor(.orange)
//                        Spacer()
//                    }
//                    .padding(.top, 10)
//
//                    HStack {
//                        Text("On \(heartRateViewModel.therapyType.rawValue) Days")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .padding(.leading, 10) // Horizontal padding on the inside
//                        Spacer()
//                        Text(heartRateViewModel.avgHeartRateSleepTherapyDays.formatBPM())
//                            .font(.system(size: 18, weight: .bold, design: .monospaced))
//                            .fontWeight(.bold)
//                            .foregroundColor(.white) // Change to a different color for therapy days
//                            .padding(.trailing, 10) // Horizontal padding on the inside
//                    }
//                    .padding(.vertical, 5) // Provide some space
//                    .background(heartRateViewModel.therapyType.color.opacity(0.2)) // Different background for therapy days
//                    .cornerRadius(15) // Adds rounded corners
//
//                    HStack {
//                        Text("Off Days")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .padding(.leading, 10)
//                        Spacer()
//                        Text(heartRateViewModel.avgHeartRateSleepNonTherapyDays.formatBPM())
//                            .font(.system(size: 18, weight: .semibold, design: .monospaced)) // Make the font weight a bit lighter
//                            .foregroundColor(.white)
//                            .padding(.trailing, 10)
//                    }
//                    .padding(.vertical, 5) // Provide some space
//                }
//                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
            .background(Color(.darkGray))
            .cornerRadius(16)
            .padding(.horizontal)
            .transition(.opacity) // The view will fade in when it appears
            .animation(.easeIn)
        }
    }
}

struct HeartRateDifferenceView: View {
    let differencePercentage: Double
    let therapyType: String
    let isIncreased: Bool
    let heartRateType: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isIncreased ? "arrow.up" : "arrow.down")
                .foregroundColor(isIncreased ? .red : .green)
            
            Text("\(heartRateType)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(8)
            
            Text("\(isIncreased ? "Up" : "Down") \(differencePercentage, specifier: "%.1f")%")
                .font(.headline)
                .foregroundColor(.white)
                .padding(8)
                .background(isIncreased ? Color.red : Color.green)
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.bottom)
    }
}
