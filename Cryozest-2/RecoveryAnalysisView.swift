import SwiftUI

class SleepViewModel: ObservableObject {
    
    // Average sleep duration
    @Published var avgSleepDurationTherapyDays: Double = 0.0
    @Published var avgSleepDurationNonTherapyDays: Double = 0.0
    
    // Average Heart Rate during sleep
    @Published var sleepingHeartRateTherapyDays: Double = 0.0
    // @Published var sleepingHeartRateNonTherapyDays: Double = 0.0 // TODO: ADD THIS IN
    
    // Baseline metrics
    @Published var baselineSleepingDuration: Double = 0.0
    @Published var baselineSleepingHeartRate: Double = 0.0
    
    @Published var isLoading: Bool = true
    @Published var timeFrame: TimeFrame {
        didSet {
            if oldValue != timeFrame {
                fetchRecoveryData()
            }
        }
    }
    @Published var therapyType: TherapyType {
        didSet {
            if oldValue != therapyType {
                fetchRecoveryData()
            }
        }
    }
    
    var sessions: FetchedResults<TherapySessionEntity>
    var healthKitManager = HealthKitManager.shared
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.therapyType = therapyType
        self.timeFrame = timeFrame
        self.sessions = sessions
        fetchRecoveryData()
    }
    
    func fetchRecoveryData() {
        isLoading = true
        
        let group = DispatchGroup()
        
        fetchDataForTherapyDays(group: group)
        
        // fetchDataNonTherapyDays(group: group)
        
        HealthKitManager.shared.fetchAvgSleepDurationForLastNDays(numDays: timeFrame.numberOfDays()) { duration in
            DispatchQueue.main.async {
                if let duration = duration {
                    self.baselineSleepingDuration = duration / 3600
                }
            }
        }
        
        HealthKitManager.shared.fetchAvgHeartRateDuringSleepForLastNDays(numDays: timeFrame.numberOfDays()) { heartRate in
            DispatchQueue.main.async {
                if let heartRate = heartRate {
                    self.baselineSleepingHeartRate = heartRate
                }
            }
        }
        
        // Stop showing ghost card once data is available.
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    private func fetchDataForTherapyDays(group: DispatchGroup) {
        let completedSessionDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
    
        group.enter()
        healthKitManager.fetchAvgHeartRateDuringSleepForDays(days: completedSessionDates) { avgHeartRate in
            if let avgHeartRate = avgHeartRate {
                self.sleepingHeartRateTherapyDays = avgHeartRate
            }
            group.leave()
        }
        
        group.enter()
        healthKitManager.fetchAvgSleepDurationForDays(days: completedSessionDates) { avgSleep in
            if let avgSleep = avgSleep {
                self.avgSleepDurationTherapyDays = Double(String(format: "%.1f", avgSleep/3600)) ?? 0.0
            }
            group.leave()
        }
    }
}

struct RecoveryAnalysisView: View {
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @ObservedObject var viewModel: SleepViewModel
    
    var body: some View {
        
        if viewModel.isLoading {
            LoadingView()
        } else {
            VStack(alignment: .leading) {
                HStack {
                    Text("Sleep \(viewModel.timeFrame.presentDisplayString())")
                        .font(.system(size: 24, weight: .regular, design: .default))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    Spacer()
                    
                    Text(viewModel.therapyType.displayName(managedObjectContext))
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(viewModel.therapyType.color)
                        .cornerRadius(8)
                }
                
                HStack {
                    Spacer()
                    Text("baseline")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color(white: 0.8), Color(white: 0.6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .cornerRadius(8)
                }
                
                SleepComparisonBarGraph(model: SleepComparisonDataModel(therapyType: viewModel.therapyType, timeFrame: viewModel.timeFrame, sessions: viewModel.sessions))
                
                SleepVitalsGraph(model: SleepVitalsDataModel(therapyType: viewModel.therapyType, timeFrame: viewModel.timeFrame, sessions: viewModel.sessions))
                    .padding(.top, 32)
            }
            .padding(.horizontal)
            .cornerRadius(16)
            .transition(.opacity)
            .animation(.easeIn)
        }
    }
}

