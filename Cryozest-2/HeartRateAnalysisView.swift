import SwiftUI

class HeartRateViewModel: ObservableObject {
    
    // Average Heart Rate Values
    @Published var avgHeartRateTherapyDays: Double = 0.0
    @Published var avgHeartRateNonTherapyDays: Double = 0.0
    
    // Resting Heart Rate Values
    @Published var restingHeartRateTherapyDays: Double = 0.0
    @Published var restingHeartRateNonTherapyDays: Double = 0.0
    
    @Published var restingHeartRateDifference: Double = 0.0
    @Published var avgHeartRateDifference: Double = 0.0
    
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
            print("Resting heart rate on therapy days is zero, can't calculate difference.")
        }
    }
    
    private func calculateAvgHRDifference() {
        if avgHeartRateTherapyDays != 0 {
            let differenceValue = (avgHeartRateTherapyDays - avgHeartRateNonTherapyDays) / avgHeartRateNonTherapyDays * 100
            avgHeartRateDifference = differenceValue
        } else {
            print("Resting heart rate on therapy days is zero, can't calculate difference.")
        }
    }
    
    
    private func fetchrestingHeartRateTherapyDays(group: DispatchGroup) {
        let completedSessionDates = sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
        
        print("completed session days: ", completedSessionDates)
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.restingHeartRateTherapyDays = avgHeartRateExcluding
                self.calculateRestingHRDifference()
            } else {
                print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.avgHeartRateTherapyDays = avgHeartRateExcluding
                self.calculateAvgHRDifference()
            } else {
                print("Owen here. Failed to fetch average heart rate excluding specific days.")
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
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: lastMonthDates) { fetchedAvgHeartRateExcluding in
            if let fetchedAvgHeartRateExcluding = fetchedAvgHeartRateExcluding {
                self.restingHeartRateNonTherapyDays = fetchedAvgHeartRateExcluding
                self.calculateRestingHRDifference()
            } else {
                print("Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: lastMonthDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.avgHeartRateNonTherapyDays = avgHeartRateExcluding
                self.calculateAvgHRDifference()
            } else {
                print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
    }
}

extension Double {
    func formatBPM() -> String {
        return self == 0.0 ? "N/A" : String(format: "%.2f bpm", self)
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
                    
                    HStack {
                        Text("Resting Heart Rate")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    
                    HStack {
                        Text("On \(heartRateViewModel.therapyType.rawValue) Days")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(heartRateViewModel.restingHeartRateTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("On Non-\(heartRateViewModel.therapyType.rawValue) Days")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(heartRateViewModel.restingHeartRateNonTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 10)
                
                VStack {
                    HStack {
                        Text("Avg Heart Rate")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    
                    HStack {
                        Text("On \(heartRateViewModel.therapyType.rawValue) Days")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(heartRateViewModel.avgHeartRateTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("On Non-\(heartRateViewModel.therapyType.rawValue) Days")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(heartRateViewModel.avgHeartRateNonTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
            .background(Color(.darkGray))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

struct HeartRateDifferenceView: View {
    let differencePercentage: Double
    let therapyType: String
    let isIncreased: Bool
    let heartRateType: String
    
    var body: some View {
        HStack {
            Image(systemName: isIncreased ? "arrow.up" : "arrow.down")
                .foregroundColor(isIncreased ? .red : .green)
            
            let differenceLabel = isIncreased ? "increase" : "decrease"
            
            Text("\(differencePercentage, specifier: "%.2f")% \(differenceLabel) in \(heartRateType) on \(therapyType) days")
                .font(.headline)
                .foregroundColor(isIncreased ? .red : .green)
            
            Spacer()
        }
        .padding(.bottom)
    }
}
