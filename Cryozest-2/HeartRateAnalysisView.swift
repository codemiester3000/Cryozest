import SwiftUI

class HeartRateViewModel: ObservableObject {
    
    // Average Heart Rate Values
    @Published var avgHeartRateTherapyDays: Double = 0.0
    
    // Resting Heart Rate Values
    @Published var restingHeartRateTherapyDays: Double = 0.0
    
    // Baseline heart rate values
    @Published var baselineRestingHeartRate: Double = 0.0
    @Published var baselineHeartRate: Double = 0.0
    
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
            let differenceValue = (restingHeartRateTherapyDays - baselineRestingHeartRate) / baselineRestingHeartRate * 100
            restingHeartRateDifference = differenceValue
        }
    }
    
    private func calculateAvgHRDifference() {
        if avgHeartRateTherapyDays != 0 {
            let differenceValue = (avgHeartRateTherapyDays - baselineHeartRate) / baselineHeartRate * 100
            avgHeartRateDifference = differenceValue
        }
    }
    
    func fetchHeartRates() {
        self.isLoading = true
        let group = DispatchGroup()
        
        fetchrestingHeartRateTherapyDays(group: group)
        
        // fetchrestingHeartRateNonTherapyDays(group: group)
        
        HealthKitManager.shared.fetchNDayAvgRestingHeartRate(numDays: timeFrame.numberOfDays()) { restingHeartRate in
            DispatchQueue.main.async {
                if let restingHeartRate = restingHeartRate {
                    self.baselineRestingHeartRate = Double(restingHeartRate)
                }
            }
        }
        
        HealthKitManager.shared.fetchNDayAvgOverallHeartRate(numDays: timeFrame.numberOfDays()) { heartRate in
            DispatchQueue.main.async {
                if let heartRate = heartRate {
                    self.baselineHeartRate = Double(heartRate)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    private func fetchrestingHeartRateTherapyDays(group: DispatchGroup) {
        let completedSessionDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
        
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
}

extension Double {
    func formatBPM() -> String {
        return self == 0.0 ? "N/A" : String(format: "%.0f bpm", self)
    }
}

struct AvgHeartRateComparisonView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @ObservedObject var heartRateViewModel: HeartRateViewModel
    
    var body: some View {
        
        if heartRateViewModel.isLoading {
            LoadingView()
        }
        else {
            VStack() {
                HStack {
                    Text("Heart Rate Analysis")
                        .font(.system(size: 24, weight: .regular, design: .default))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    Spacer()
                    
                    Text(heartRateViewModel.timeFrame.displayString())
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(heartRateViewModel.therapyType.color)
                        .cornerRadius(8)
                        .padding(.bottom, 10)
                }
                
                Divider().background(Color.darkBackground.opacity(0.8))
                
                VStack {
                    // Resting Heart Rate View.
                    HStack {
                        Text("Resting Heart Rate")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(heartRateViewModel.therapyType.color)
                            .padding(.trailing, 10)
                        
                    }
                    HStack {
                        HStack {
                            Text("\(heartRateViewModel.therapyType.displayName(managedObjectContext)) days")
                                .font(.footnote)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        Text(heartRateViewModel.restingHeartRateTherapyDays.formatBPM())
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5)
                    
                    HStack {
                        HStack {
                            Text("baseline")
                                .font(.footnote)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text(heartRateViewModel.baselineRestingHeartRate.formatBPM())
                            .font(.footnote)
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
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(heartRateViewModel.therapyType.color)
                            .padding(.trailing, 10)
                    }
                    
                    HStack {
                        HStack {
                            
                            Text("\(heartRateViewModel.therapyType.displayName(managedObjectContext)) days")
                                .font(.footnote)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text(heartRateViewModel.avgHeartRateTherapyDays.formatBPM())
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5)
                    
                    HStack {
                        HStack {
                            Text("baseline")
                                .font(.footnote)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        Text(heartRateViewModel.baselineHeartRate.formatBPM())
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.top, 10)
            }
            .padding(.horizontal)
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
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.white)
                .padding(8)
            
            Text("\(isIncreased ? "Up" : "Down") \(differencePercentage, specifier: "%.1f")%")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.white)
                .padding(8)
                .background(isIncreased ? Color.red : Color.green)
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.bottom)
    }
}
