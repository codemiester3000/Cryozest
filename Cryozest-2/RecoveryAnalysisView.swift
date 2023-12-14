import SwiftUI

class SleepViewModel: ObservableObject {
    
    // Average sleep duration
    @Published var avgSleepDurationTherapyDays: Double = 0.0
    @Published var avgSleepDurationNonTherapyDays: Double = 0.0
    
    // Average Heart Rate during sleep
    @Published var sleepingHeartRateTherapyDays: Double = 0.0
    @Published var sleepingHeartRateNonTherapyDays: Double = 0.0
    
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
        
        fetchDataNonTherapyDays(group: group)
        
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
    
    private func fetchDataNonTherapyDays(group: DispatchGroup) {
        let completedSessionDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
        let timeFrameDates = DateUtils.shared.getDatesForTimeFrame(timeFrame: timeFrame, fromStartDate: Date())
        let nonTherapyDates = DateUtils.shared.getDatesExcluding(excludeDates: completedSessionDates, inDates: timeFrameDates)
        
        group.enter()
        healthKitManager.fetchAvgHeartRateDuringSleepForDays(days: nonTherapyDates) { avgHeartRate in
            if let avgHeartRate = avgHeartRate {
                self.sleepingHeartRateNonTherapyDays = avgHeartRate
            }
            group.leave()
        }
        
        group.enter()
        healthKitManager.fetchAvgSleepDurationForDays(days: nonTherapyDates) { avgSleep in
            if let avgSleep = avgSleep {
                self.avgSleepDurationNonTherapyDays =  Double(String(format: "%.1f", avgSleep/3600)) ?? 0.0
            }
            group.leave()
        }
    }
}


struct RecoveryAnalysisView: View {
    
    @ObservedObject var viewModel: SleepViewModel
    
    var body: some View {
        
        if viewModel.isLoading {
            LoadingView()
        } else {
            VStack(alignment: .leading, spacing: 16) {
                
                Text("Recovery")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
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
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(.darkBackground)
                        Spacer()
                    }
                    HStack {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .padding(.leading, 10)
                            
                            Text("On \(viewModel.therapyType.rawValue) Days")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                        }
                        Spacer()
                        Text((viewModel.avgSleepDurationTherapyDays != 0 ? String(format: "%.1f", viewModel.avgSleepDurationTherapyDays) + " Hrs" : "N/A"))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5) // Provide some space
//                    .background(viewModel.therapyType.color.opacity(0.2))
//                    .cornerRadius(15) // Adds rounded corners
                    HStack {
                        HStack {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                                .padding(.leading, 10)
                            
                            Text("Off Days")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                        }
                        Spacer()
                        Text((viewModel.avgSleepDurationNonTherapyDays != 0 ? String(format: "%.1f", viewModel.avgSleepDurationNonTherapyDays) + " Hrs" : "N/A"))
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
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(.darkBackground)
                        Spacer()
                    }
                    HStack {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .padding(.leading, 10)
                            
                            Text("On \(viewModel.therapyType.rawValue) Days")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                        }
                        Spacer()
                        Text((viewModel.sleepingHeartRateTherapyDays != 0 ? String(format: "%.1f", viewModel.sleepingHeartRateTherapyDays) + " BPM" : "N/A"))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                    .padding(.vertical, 5) // Provide some space
//                    .background(viewModel.therapyType.color.opacity(0.2))
//                    .cornerRadius(15) // Adds rounded corners
                    HStack {
                        HStack {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                                .padding(.leading, 10)
                            
                            Text("Off Days")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                        }
                        Spacer()
                        Text((viewModel.sleepingHeartRateNonTherapyDays != 0 ? String(format: "%.1f", viewModel.sleepingHeartRateNonTherapyDays) + " BPM" : "N/A"))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
//            .background(Color(.darkGray).opacity(0.95))
            .cornerRadius(16)
//            .padding(.horizontal)
            .transition(.opacity) // The view will fade in when it appears
            .animation(.easeIn)
        }
    }
}

