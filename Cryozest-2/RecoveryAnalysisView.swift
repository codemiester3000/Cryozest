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
        
        print("fetchDataForTherapyDays ", completedSessionDates)
        
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
    
//    private func fetchDataNonTherapyDays(group: DispatchGroup) {
//        let completedSessionDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
//        let timeFrameDates = DateUtils.shared.getDatesForTimeFrame(timeFrame: timeFrame, fromStartDate: Date())
//        let nonTherapyDates = DateUtils.shared.getDatesExcluding(excludeDates: completedSessionDates, inDates: timeFrameDates)
//        
////        group.enter()
////        healthKitManager.fetchAvgHeartRateDuringSleepForDays(days: nonTherapyDates) { avgHeartRate in
////            if let avgHeartRate = avgHeartRate {
////                self.sleepingHeartRateNonTherapyDays = avgHeartRate
////            }
////            group.leave()
////        }
//        
//        group.enter()
//        healthKitManager.fetchAvgSleepDurationForDays(days: nonTherapyDates) { avgSleep in
//            if let avgSleep = avgSleep {
//                self.avgSleepDurationNonTherapyDays =  Double(String(format: "%.1f", avgSleep/3600)) ?? 0.0
//            }
//            group.leave()
//        }
//    }
}


struct RecoveryAnalysisView: View {
    
    @ObservedObject var viewModel: SleepViewModel
    
    var body: some View {
        
        if viewModel.isLoading {
            LoadingView()
        } else {
            VStack(alignment: .leading, spacing: 16) {
                
                Text("Recovery Analysis")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 10)
                
                Text(viewModel.timeFrame.displayString())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(viewModel.therapyType.color)
                    .cornerRadius(8)
                
                Divider().background(Color.darkBackground.opacity(0.8)).padding(.vertical, 10)
                
                // Sleep data
                VStack {
                    HStack {
                        Text("Avg Sleep Duration")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                        
                        Image(systemName: "moon.fill")
                            .foregroundColor(viewModel.therapyType.color)
                            .padding(.trailing, 10)
                    }
                    HStack {
                        HStack {
                            Text("\(viewModel.therapyType.rawValue) days")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                        }
                        Spacer()
                        Text((viewModel.avgSleepDurationTherapyDays != 0 ? String(format: "%.1f", viewModel.avgSleepDurationTherapyDays) + " Hrs" : "N/A"))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5)
                    HStack {
                        HStack {
                            
                            Text("baseline")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        Spacer()
                        Text((viewModel.baselineSleepingDuration != 0 ? String(format: "%.1f", viewModel.baselineSleepingDuration) + " Hrs" : "N/A"))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                }
                
                Divider().background(Color.darkBackground.opacity(0.8)).padding(.vertical, 4)
                
                // Heart Rate Data
                VStack {
                    HStack {
                        Text("Avg Sleeping HR")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(viewModel.therapyType.color)
                            .padding(.trailing, 10)
                    }
                    HStack {
                        HStack {
                            
                            
                            Text("\(viewModel.therapyType.rawValue) days")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                        }
                        Spacer()
                        Text((viewModel.sleepingHeartRateTherapyDays != 0 ? String(format: "%.1f", viewModel.sleepingHeartRateTherapyDays) + " BPM" : "N/A"))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5)
                    HStack {
                        HStack {
                            Text("baseline")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                        }
                        Spacer()
                        Text((viewModel.baselineSleepingHeartRate != 0 ? String(format: "%.1f", viewModel.baselineSleepingHeartRate) + " BPM" : "N/A"))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
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

