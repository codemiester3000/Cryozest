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
                fetchSleepData()
            }
        }
    }
    @Published var therapyType: TherapyType {
        didSet {
            if oldValue != therapyType {
                fetchSleepData()
            }
        }
    }
    
    var sessions: FetchedResults<TherapySessionEntity>
    var healthKitManager = HealthKitManager.shared
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.therapyType = therapyType
        self.timeFrame = timeFrame
        self.sessions = sessions
        fetchSleepData()
    }
    
    func fetchSleepData() {
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
        let completedSessionDates = sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
        
        group.enter()
        healthKitManager.fetchAvgHeartRateDuringSleepForDays(days: completedSessionDates) { avgHeartRate in
            if let avgHeartRate = avgHeartRate {
                self.sleepingHeartRateTherapyDays = avgHeartRate
            }
        }
        group.leave()
        
        group.enter()
        healthKitManager.fetchAvgSleepDurationForDays(days: completedSessionDates) { avgSleep in
            if let avgSleep = avgSleep {
                self.avgSleepDurationTherapyDays = Double(String(format: "%.1f", avgSleep/3600)) ?? 0.0
            }
        }
        group.leave()
    }
    
    private func fetchDataNonTherapyDays(group: DispatchGroup) {
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
        var timeFrameDates = [Date]()
        for day in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: -day, to: Date()),
               !completedSessionDates.contains(date),
               date >= dateOneMonthAgo {
                timeFrameDates.append(date)
            }
        }
        
        print("Recovery analysis: ", timeFrameDates)
        
        group.enter()
        healthKitManager.fetchAvgHeartRateDuringSleepForDays(days: timeFrameDates) { avgHeartRate in
            if let avgHeartRate = avgHeartRate {
                self.sleepingHeartRateNonTherapyDays = avgHeartRate
            }
        }
        group.leave()
        
        group.enter()
        healthKitManager.fetchAvgSleepDurationForDays(days: timeFrameDates) { avgSleep in
            if let avgSleep = avgSleep {
                self.avgSleepDurationNonTherapyDays =  Double(String(format: "%.1f", avgSleep/3600)) ?? 0.0
            }
        }
        group.leave()
    }
}


struct RecoveryAnalysisView: View {
    
    @ObservedObject var viewModel: SleepViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Recovery")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(viewModel.timeFrame.displayString())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(viewModel.therapyType.color)
                    .cornerRadius(8)
            }
            .padding(.bottom, 10)
            
            HStack {
                Text("Avg Sleep Duration")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Spacer()
            }
            HStack {
                Text("On \(viewModel.therapyType.rawValue) Days")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.leading, 10)
                Spacer()
                Text("\(viewModel.avgSleepDurationTherapyDays, specifier: "%.1f") Hrs")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
            }
            .padding(.vertical, 5) // Provide some space
            .background(viewModel.therapyType.color.opacity(0.2))
            .cornerRadius(15) // Adds rounded corners
            HStack {
                Text("Off Days")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.leading, 10)
                Spacer()
                Text("\(viewModel.avgSleepDurationNonTherapyDays, specifier: "%.1f") Hrs")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
        .background(Color(.darkGray))
        .cornerRadius(16)
        .padding(.horizontal)
        .transition(.opacity) // The view will fade in when it appears
        .animation(.easeIn)
        .onAppear {
            viewModel.fetchSleepData()
        }
    }
}

