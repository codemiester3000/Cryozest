import SwiftUI

class HeartRateViewModel: ObservableObject {
    @Published var restingHeartRateOnTherapyDays: Double = 0.0
    @Published var avgHeartRateOnNonTherapyDays: Double = 0.0
    
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
        fetchRestingHeartRateOnTherapyDays()
        fetchAvgHeartRateOnNonTherapyDays()
    }
    
    private func calculateDifference() {
        if restingHeartRateOnTherapyDays != 0 {
            let differenceValue = (avgHeartRateOnNonTherapyDays - restingHeartRateOnTherapyDays) / restingHeartRateOnTherapyDays * 100
            difference = differenceValue
        } else {
            print("Resting heart rate on therapy days is zero, can't calculate difference.")
        }
    }
    
    private func fetchRestingHeartRateOnTherapyDays() {
        let completedSessionDates = sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
        
        print("completed session days: ", completedSessionDates)
        
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.restingHeartRateOnTherapyDays = avgHeartRateExcluding
                self.calculateDifference()
            } else {
                print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
        }
    }
    
    private func fetchAvgHeartRateOnNonTherapyDays() {
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
                
                print("success ", fetchedAvgHeartRateExcluding)
                
                self.avgHeartRateOnNonTherapyDays = fetchedAvgHeartRateExcluding
                self.calculateDifference()
            } else {
                print("Failed to fetch average heart rate excluding specific days.")
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
                        
                        Text("You have a \(differencePercentage, specifier: "%.2f")% \(differenceLabel) in HR on \(therapyType) days")
                            .font(.headline)
                            .foregroundColor(heartRateViewModel.difference >= 0 ? .green : .red)
                    }
                    .padding(.bottom)
                }

                
                HStack {
                    Text("On \(heartRateViewModel.therapyType.rawValue) Days")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(heartRateViewModel.restingHeartRateOnTherapyDays, specifier: "%.2f") bpm")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("On Non-\(heartRateViewModel.therapyType.rawValue) Days")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(heartRateViewModel.avgHeartRateOnNonTherapyDays, specifier: "%.2f") bpm")
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

