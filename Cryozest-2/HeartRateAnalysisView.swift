import SwiftUI

class HeartRateViewModel: ObservableObject {
    
    // Average Heart Rate Values
    @Published var avgHeartRateTherapyDays: Double = 0.0
    @Published var avgHeartRateNonTherapyDays: Double = 0.0
    
    // Resting Heart Rate Values
    @Published var restingHeartRateTherapyDays: Double = 0.0
    @Published var restingHeartRateNonTherapyDays: Double = 0.0
    
    @Published var difference: Double = 0.0
    
    @Published var therapyType: TherapyType {
        didSet {
            fetchHeartRates()
        }
    }
    var sessions: FetchedResults<TherapySessionEntity>
    
    init(therapyType: TherapyType, sessions: FetchedResults<TherapySessionEntity>) {
        self.therapyType = therapyType
        self.sessions = sessions
        
        fetchHeartRates()
    }
    
    func fetchHeartRates() {
        fetchrestingHeartRateTherapyDays()
        fetchrestingHeartRateNonTherapyDays()
    }
    
    private func calculateDifference() {
        if restingHeartRateTherapyDays != 0 {
            let differenceValue = (restingHeartRateNonTherapyDays - restingHeartRateTherapyDays) / restingHeartRateTherapyDays * 100
            difference = differenceValue
        } else {
            print("Resting heart rate on therapy days is zero, can't calculate difference.")
        }
    }
    
    private func fetchrestingHeartRateTherapyDays() {
        let completedSessionDates = sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
        
        print("completed session days: ", completedSessionDates)
        
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.restingHeartRateTherapyDays = avgHeartRateExcluding
                self.calculateDifference()
            } else {
                print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
        }
        
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.avgHeartRateTherapyDays = avgHeartRateExcluding
            } else {
                print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
        }
    }
    
    private func fetchrestingHeartRateNonTherapyDays() {
        let completedSessionDates = sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
        
        // Get the dates for the last month.
        let calendar = Calendar.current
        let dateOneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        
        // Exclude completedSessionDates from the last month's dates.
        var lastMonthDates = [Date]()
        for day in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -day, to: Date()),
               !completedSessionDates.contains(date),
               date >= dateOneMonthAgo {
                lastMonthDates.append(date)
            }
        }
        
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: lastMonthDates) { fetchedAvgHeartRateExcluding in
            if let fetchedAvgHeartRateExcluding = fetchedAvgHeartRateExcluding {
                self.restingHeartRateNonTherapyDays = fetchedAvgHeartRateExcluding
                self.calculateDifference()
            } else {
                print("Failed to fetch average heart rate excluding specific days.")
            }
        }
        
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: lastMonthDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.avgHeartRateNonTherapyDays = avgHeartRateExcluding
            } else {
                print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
        }
    }
}

struct AvgHeartRateComparisonView: View {
    @ObservedObject var heartRateViewModel: HeartRateViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Heart Rate")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(heartRateViewModel.therapyType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            .padding(.bottom, 10)
            
            VStack {
                if heartRateViewModel.difference != 0 {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        let differencePercentage = abs(heartRateViewModel.difference)
                        let therapyType = heartRateViewModel.therapyType.rawValue
                        let differenceLabel = heartRateViewModel.difference <= 0 ? "increase" : "decrease"
                        
                        Text("You have a \(differencePercentage, specifier: "%.2f")% \(differenceLabel) in RHR on \(therapyType) days")
                            .font(.headline)
                            .foregroundColor(heartRateViewModel.difference >= 0 ? .green : .red)
                    }
                    .padding(.bottom)
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
                    Text("\(heartRateViewModel.restingHeartRateTherapyDays, specifier: "%.2f") bpm")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("On Non-\(heartRateViewModel.therapyType.rawValue) Days")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(heartRateViewModel.restingHeartRateNonTherapyDays, specifier: "%.2f") bpm")
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
                    Text("\(heartRateViewModel.avgHeartRateTherapyDays, specifier: "%.2f") bpm")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("On Non-\(heartRateViewModel.therapyType.rawValue) Days")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(heartRateViewModel.avgHeartRateNonTherapyDays, specifier: "%.2f") bpm")
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
        .onAppear {
            heartRateViewModel.fetchHeartRates()
        }
    }
}

