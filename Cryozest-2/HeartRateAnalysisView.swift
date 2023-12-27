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
    
    private func calculateRestingHRDifference() {
        if restingHeartRateTherapyDays != 0 {
            let differenceValue = (restingHeartRateTherapyDays - restingHeartRateNonTherapyDays) / restingHeartRateNonTherapyDays * 100
            restingHeartRateDifference = differenceValue
        }
    }
    
    private func calculateAvgHRDifference() {
        if avgHeartRateTherapyDays != 0 {
            let differenceValue = (avgHeartRateTherapyDays - avgHeartRateNonTherapyDays) / avgHeartRateNonTherapyDays * 100
            avgHeartRateDifference = differenceValue
        }
    }
    
    private func calculateAvgHRSleepDifference() {
        if avgHeartRateSleepTherapyDays != 0 {
            let differenceValue = (avgHeartRateSleepTherapyDays - avgHeartRateSleepNonTherapyDays) / avgHeartRateSleepNonTherapyDays * 100
            avgHeartRateSleepDifference = differenceValue
        }
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
    
    private func fetchrestingHeartRateTherapyDays(group: DispatchGroup) {
        let completedSessionDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
        
        print("fetchrestingHeartRateTherapyDays ", completedSessionDates)
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.restingHeartRateTherapyDays = avgHeartRateExcluding
                self.calculateRestingHRDifference()
            } else {
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
        let completedSessionDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
        let timeFrameDates = DateUtils.shared.getDatesForTimeFrame(timeFrame: timeFrame, fromStartDate: Date())
        let nonTherapyDates = DateUtils.shared.getDatesExcluding(excludeDates: completedSessionDates, inDates: timeFrameDates)
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: nonTherapyDates) { fetchedAvgHeartRateExcluding in
            if let fetchedAvgHeartRateExcluding = fetchedAvgHeartRateExcluding {
                self.restingHeartRateNonTherapyDays = fetchedAvgHeartRateExcluding
                self.calculateRestingHRDifference()
            } else {
                // print("Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: nonTherapyDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.avgHeartRateNonTherapyDays = avgHeartRateExcluding
                self.calculateAvgHRDifference()
            } else {
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
                
                Text("Heart Rate Analysis")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 10)
                
                Text(heartRateViewModel.timeFrame.displayString())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(heartRateViewModel.therapyType.color)
                    .cornerRadius(8)
                    .padding(.bottom, 10)
                
                Divider().background(Color.darkBackground.opacity(0.8))
                
                VStack {
                    
                    if heartRateViewModel.restingHeartRateDifference != 0 || heartRateViewModel.avgHeartRateDifference != 0 {
                        HStack {
                            Text("On \(heartRateViewModel.therapyType.rawValue) days")
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .bold, design: .default))
                            Spacer()
                        }
                    }
                    
                    // Heart Rate differences views.
//                    if heartRateViewModel.restingHeartRateDifference != 0 {
//                        let differencePercentage = abs(heartRateViewModel.restingHeartRateDifference)
//                        let isIncreased = heartRateViewModel.restingHeartRateDifference >= 0
//                        HeartRateDifferenceView(differencePercentage: differencePercentage,
//                                                therapyType: heartRateViewModel.therapyType.rawValue,
//                                                isIncreased: isIncreased,
//                                                heartRateType: "RHR")
//                    }
//                    
//                    if heartRateViewModel.avgHeartRateDifference != 0 {
//                        let differencePercentage = abs(heartRateViewModel.avgHeartRateDifference)
//                        let isIncreased = heartRateViewModel.avgHeartRateDifference >= 0
//                        HeartRateDifferenceView(differencePercentage: differencePercentage,
//                                                therapyType: heartRateViewModel.therapyType.rawValue,
//                                                isIncreased: isIncreased,
//                                                heartRateType: "Avg HR")
//                    }
                    
                    // Resting Heart Rate View.
                    HStack {
                        Text("Resting Heart Rate")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(heartRateViewModel.therapyType.color)
                            .padding(.trailing, 10)
                        
                    }
                    
                    
                    
                    HStack {
                        HStack {
                            Text("\(heartRateViewModel.therapyType.rawValue) days")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        Text(heartRateViewModel.restingHeartRateTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5)
                    
                    HStack {
                        HStack {
                            
                            
                            Text("off days")
                                .font(.headline)
                                .foregroundColor(.black)
                            // .padding(.leading, 10)
                        }
                        Spacer()
                        Text(heartRateViewModel.restingHeartRateNonTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.top, 10)
                
                Divider().background(Color.darkBackground.opacity(0.8)).padding(.vertical, 2)
                
                // Average Heart Rate View.
                VStack {
                    HStack {
                        Text("Avg Heart Rate")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(heartRateViewModel.therapyType.color)
                            .padding(.trailing, 10)
                    }
                    
                    HStack {
                        HStack {
                            
                            Text("\(heartRateViewModel.therapyType.rawValue) days")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        Spacer()
                        Text(heartRateViewModel.avgHeartRateTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5)
                    
                    HStack {
                        HStack {
                            Text("off days")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        Text(heartRateViewModel.avgHeartRateNonTherapyDays.formatBPM())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
            .cornerRadius(16)
            .transition(.opacity)
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
