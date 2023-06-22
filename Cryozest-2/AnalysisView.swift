import SwiftUI
import CoreData

struct AnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>
    
    let healthKitManager = HealthKitManager.shared
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var therapyType: TherapyType = .drySauna
    @State private var selectedTimeFrame: TimeFrame = .week
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"
        return df
    }()
    
    var body: some View {
        VStack {
            HStack {
                Text("Analysis")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .bold()
                    .padding(.top, 36)
                    .padding(.leading, 24)
                
                Spacer()
            }
            
            
            LazyVGrid(columns: gridItems, spacing: 10) {
                ForEach(TherapyType.allCases, id: \.self) { therapyType in
                    Button(action: {
                        self.therapyType = therapyType
                    }) {
                        HStack {
                            Image(systemName: therapyType.icon)
                                .foregroundColor(.white)
                            Text(therapyType.rawValue)
                                .font(.system(size: 15, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50)
                        .background(self.therapyType == therapyType ?
                                    (therapyType == .coldPlunge || therapyType == .meditation ? Color.blue : Color.orange)
                                    : Color(.gray))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 5)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
            .padding(.top, 20)
            
            Picker("Time frame", selection: $selectedTimeFrame) {
                Text("Last 7 days")
                    .tag(TimeFrame.week)
                    .foregroundColor(selectedTimeFrame == .week ? .orange : .primary)
                Text("Last Month")
                    .tag(TimeFrame.month)
                    .foregroundColor(selectedTimeFrame == .month ? .orange : .primary)
                Text("All Time")
                    .tag(TimeFrame.allTime)
                    .foregroundColor(selectedTimeFrame == .allTime ? .orange : .blue)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 28)
            .padding(.horizontal)
            
            ScrollView {
                SessionTimeAnalysisCard(
                    totalTime: getTotalTime(for: therapyType),
                    totalSessions: getTotalSessions(for: therapyType),
                    timeFrame: selectedTimeFrame
                )
                .padding(.horizontal)
                
                StreakAnalysisCard(
                    therapyType: self.therapyType,
                    currentStreak: getCurrentStreak(for: therapyType),
                    sessions: sessions
                )
                .padding(.horizontal)
                
                AvgHeartRateComparisonView(heartRateViewModel: HeartRateViewModel(therapyType: therapyType, sessions: sessions))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Analysis")
    }
    
    func getCurrentStreak(for therapyType: TherapyType) -> Int {
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
    
    
    func getLongestStreak(for therapyType: TherapyType) -> Int {
        var longestStreak = 0
        var currentStreak = 0
        var streakStarted = false
        
        for session in sessions {
            guard let date = session.date,
                  session.therapyType == therapyType.rawValue,
                  isWithinTimeFrame(date: date) else {
                continue
            }
            
            if streakStarted {
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else {
                streakStarted = true
                currentStreak = 1
                longestStreak = 1
            }
        }
        
        return longestStreak
    }
    
    func getTotalTime(for therapyType: TherapyType) -> TimeInterval {
        return sessions.compactMap { session -> TimeInterval? in
            guard let date = session.date,
                  session.therapyType == therapyType.rawValue,
                  isWithinTimeFrame(date: date) else {
                return nil
            }
            return session.duration
        }.reduce(0, +)
    }
    
    func getTotalSessions(for therapyType: TherapyType) -> Int {
        return sessions.filter { session in
            guard let date = session.date else {
                return false
            }
            return session.therapyType == therapyType.rawValue && isWithinTimeFrame(date: date)
        }.count
    }
    
    func isWithinTimeFrame(date: Date) -> Bool {
        switch selectedTimeFrame {
        case .week:
            return Calendar.current.isDate(date, inSameDayAs: Date())
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
    
}

enum TimeFrame {
    case week, month, allTime
    
    func displayString() -> String {
        switch self {
        case .week:
            return "Last 7 Days"
        case .month:
            return "Last Month"
        case .allTime:
            return "All Time"
        }
    }
}

struct StreakAnalysisCard: View {
    var therapyType: TherapyType
    var currentStreak: Int
    var sessions: FetchedResults<TherapySessionEntity>
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Streaks")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                Text("Current Streak:")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                Text("\(currentStreak) Days")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 10)
            
            StreakCalendarView(therapySessions: Array(sessions), therapyType: therapyType)
                .padding(.top, 10)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
        .background(Color(.darkGray))
        .cornerRadius(16)
    }
}

struct SessionTimeAnalysisCard: View {
    var totalTime: TimeInterval
    var totalSessions: Int
    var timeFrame: TimeFrame
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Time")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(timeFrame.displayString())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Sessions")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(totalSessions)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Total Time")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(Int(totalTime / 60)) mins")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
        .background(Color(.darkGray))
        .cornerRadius(16)
    }
}

struct StreakCalendarView: View {
    var therapySessions: [TherapySessionEntity]
    var therapyType: TherapyType
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(getDaysArray(), id: \.self) { day in
                VStack {
                    Text(day)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 0))
                    Circle()
                        .fill(getColorForDate(date: dateFromDay(day: day, daysInWeek: getDaysArray())))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }
    
    private func getColorForDate(date: Date) -> Color {
        if isDateInFuture(date: date) {
            return Color.gray
        } else if didHaveTherapyOnDate(date: date) {
            return Color.green
        } else {
            return Color.red
        }
    }
    
    private func didHaveTherapyOnDate(date: Date) -> Bool {
        return therapySessions.contains(where: { session in
            guard let sessionDate = session.date else {
                return false
            }
            
            let sessionDay = Calendar.current.startOfDay(for: sessionDate)
            let checkDay = Calendar.current.startOfDay(for: date)
            
            return Calendar.current.isDate(sessionDay, inSameDayAs: checkDay) && session.therapyType == therapyType.rawValue
        })
    }
    
    private func getDaysArray() -> [String] {
        let daysInWeek = Calendar.current.shortWeekdaySymbols
        let today = Calendar.current.component(.weekday, from: Date())
        var lastSevenDays = [String]()
        
        for i in 0..<7 {
            let index = (today - i - 1 + 7) % 7
            lastSevenDays.insert(daysInWeek[index], at: 0)
        }
        
        return lastSevenDays
    }
    
    private func dateFromDay(day: String, daysInWeek: [String]) -> Date {
        let index = daysInWeek.firstIndex(of: day)! - 6
        return Calendar.current.date(byAdding: .day, value: index, to: Date())!
    }
    
    private func isDateInFuture(date: Date) -> Bool {
        return date > Date()
    }
}
