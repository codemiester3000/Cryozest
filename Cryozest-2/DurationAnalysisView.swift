import SwiftUI
import CoreData

class DurationAnalysisViewModel: ObservableObject {
    @Published var therapyType: TherapyType
    @Published var timeFrame: TimeFrame
    @Published var sessions: FetchedResults<TherapySessionEntity>
    
    @Published var totalTime: TimeInterval = 0
    @Published var totalSessions: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var isLoading: Bool = true
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.therapyType = therapyType
        self.timeFrame = timeFrame
        self.sessions = sessions
        
        updateData()
    }
    
    func updateData() {
        totalTime = getTotalTime()
        totalSessions = getTotalSessions()
        currentStreak = getCurrentStreak()
        longestStreak = getLongestStreak()
    }
    
    func getCurrentStreak() -> Int {
        var currentStreak = 0
        let sortedSessions = sessions.filter { $0.therapyType == therapyType.rawValue }.sorted { $0.date! > $1.date! }
        var currentDate = Date()
        
        for session in sortedSessions {
            guard let date = session.date else {
                continue
            }
            if !Calendar.current.isDate(date, inSameDayAs: currentDate) {
                break
            }
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            currentStreak += 1
        }
        
        return currentStreak
    }
    
    func getLongestStreak() -> Int {
        // Filter sessions to only include those of the required therapy type and sort them in descending order by date
        let sortedSessions = sessions.filter { $0.therapyType == therapyType.rawValue }
            .sorted { $0.date! > $1.date! }
        
        var longestStreak = 0 // Store the longest streak
        var currentStreak = 0 // Store the current streak
        var currentDate: Date? = nil // Store the date of the last processed session
        
        // Loop over the sorted sessions
        for session in sortedSessions {
            guard let sessionDate = session.date, // Safely unwrap the session date
                  isWithinTimeFrame(date: sessionDate) else { // Check if the session is within the specified time frame
                continue // If not, move to the next session
            }
            
            // If currentDate is not set (first session) or the session
            // is not on the same day as currentDate.
            if currentDate == nil || !Calendar.current.isDate(sessionDate, inSameDayAs: currentDate!) {
                currentDate = sessionDate // Set currentDate to the session date
                currentStreak += 1 // Increase the current streak
                if currentStreak > longestStreak { // If the current streak is now longer than the longest streak
                    longestStreak = currentStreak // Update the longest streak
                }
            }
            
            // If currentDate is set and the session is not the day after currentDate
            if currentDate != nil && !Calendar.current.isDateInYesterday(sessionDate) {
                // Calculate the gap between the session date and currentDate
                let gap = Calendar.current.dateComponents([.day], from: sessionDate, to: currentDate!).day!
                if gap > 1 { // If the gap is more than a day
                    currentStreak = 1 // Reset the current streak
                }
                currentDate = sessionDate // Set currentDate to the session date
            }
        }
        
        return longestStreak // Return the longest streak
    }
    
    
    func getTotalTime() -> TimeInterval {
        return sessions.compactMap { session -> TimeInterval? in
            guard let date = session.date,
                  session.therapyType == therapyType.rawValue,
                  isWithinTimeFrame(date: date) else {
                return nil
            }
            return session.duration
        }.reduce(0, +)
    }
    
    func getTotalSessions() -> Int {
        return sessions.filter { session in
            guard let date = session.date else {
                return false
            }
            return session.therapyType == therapyType.rawValue && isWithinTimeFrame(date: date)
        }.count
    }
    
    func isWithinTimeFrame(date: Date) -> Bool {
        switch self.timeFrame {
        case .week:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            let dateInterval = DateInterval(start: oneWeekAgo, end: Date())
            return dateInterval.contains(date)
        case .month:
            guard let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else {
                return false
            }
            let dateInterval = DateInterval(start: oneMonthAgo, end: Date())
            return dateInterval.contains(date)
        case .allTime:
            return true
        }
    }
    
    func startLoading() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isLoading = false
        }
    }
}

struct DurationAnalysisView: View {
    @ObservedObject var viewModel: DurationAnalysisViewModel
    
    var body: some View {
        VStack() {
            HStack(alignment: .center) {
                Text("Overall Analysis")
                    .font(.system(size: 24, weight: .regular, design: .default))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                Spacer()
                Text(viewModel.timeFrame.displayString())
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(viewModel.therapyType.color)
                    .cornerRadius(8)
            }
            
            Divider().background(Color.darkBackground.opacity(0.8))
            
            VStack {
                HStack {
                    Text("Completed")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(viewModel.totalSessions) sessions")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .cornerRadius(8)
                }
                
                Divider().background(Color.darkBackground.opacity(0.8))
                
                HStack {
                    Text("Time")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(viewModel.totalTime / 60)) mins")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .cornerRadius(15)
                }
                
                Divider().background(Color.darkBackground.opacity(0.8))
                
                HStack {
                    Text("Current streak")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(viewModel.currentStreak) days")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .cornerRadius(15)
                }
                
                Divider().background(Color.darkBackground.opacity(0.8))
                
                HStack {
                    Text("Longest streak")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(viewModel.longestStreak) days")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .cornerRadius(15)
                }
            }
            ///.padding(.horizontal)
        }
        .background(Color(.darkGray).opacity(0.0))
        .cornerRadius(16)
        .transition(.opacity)
        .animation(.easeIn)
        .onAppear {
            viewModel.startLoading()
            viewModel.updateData()
        }
        .onReceive(viewModel.$therapyType) { _ in
            viewModel.startLoading()
            viewModel.updateData()
        }
    }
}

