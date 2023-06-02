import SwiftUI
import CoreData

struct AnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>
    
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
            Text("Analysis")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(Color.white)
            
            LazyVGrid(columns: gridItems, spacing: 10) {
                ForEach(TherapyType.allCases, id: \.self) { therapyType in
                    Button(action: {
                        self.therapyType = therapyType
                    }) {
                        HStack {
                            Image(systemName: therapyType.icon)
                                .foregroundColor(.white) // Here
                            Text(therapyType.rawValue)
                                .font(.system(size: 15, design: .monospaced)) // Smaller font
                                .foregroundColor(.white) // Here
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50) // Smaller button
                        .background(self.therapyType == therapyType ?
                                    (therapyType == .coldPlunge || therapyType == .coldShower ? Color.blue : Color.orange)
                                    : Color(.darkGray))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 5) // Less padding
                }
            }
            .padding(.horizontal, 10) // Less horizontal padding for the grid
            .padding(.bottom, 20) // Less bottom padding for the grid
            .padding(.top, 20) // Less top padding for the grid
            
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
            
            
            AnalysisCard(therapyType: self.therapyType,
                         currentStreak: getCurrentStreak(for: therapyType),
                         longestStreak: getLongestStreak(for: therapyType),
                         totalTime: getTotalTime(for: therapyType),
                         totalSessions: getTotalSessions(for: therapyType),
                         timeFrame: selectedTimeFrame,
                         sessions: sessions)
            .padding(.horizontal)
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
            guard let dateString = session.date, let date = dateFormatter.date(from: dateString) else {
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
            guard let dateString = session.date,
                  let date = dateFormatter.date(from: dateString),
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
            guard let dateString = session.date,
                  let date = dateFormatter.date(from: dateString),
                  session.therapyType == therapyType.rawValue,
                  isWithinTimeFrame(date: date) else {
                return nil
            }
            return session.duration
        }.reduce(0, +)
    }
    
    func getTotalSessions(for therapyType: TherapyType) -> Int {
        return sessions.filter { session in
            guard let dateString = session.date,
                  let date = dateFormatter.date(from: dateString) else {
                return false
            }
            return session.therapyType == therapyType.rawValue && isWithinTimeFrame(date: date)
        }.count
    }
    
    func isWithinTimeFrame(date: Date) -> Bool {
        switch selectedTimeFrame {
        case .week:
            return Calendar.current.dateComponents([.weekOfYear], from: date, to: Date()).weekOfYear == 0
        case .month:
            return Calendar.current.dateComponents([.month], from: date, to: Date()).month == 0
        case .allTime:
            return true
        }
    }
}

enum TimeFrame {
    case week, month, allTime
}

struct AnalysisCard: View {
    var therapyType: TherapyType
    var currentStreak: Int
    var longestStreak: Int
    var totalTime: TimeInterval
    var totalSessions: Int
    var timeFrame: TimeFrame
    
    var sessions: FetchedResults<TherapySessionEntity>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(therapyType.rawValue)
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
            .padding(.bottom, 10)
            
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
            
            //            HStack {
            //                VStack(alignment: .leading) {
            //                    Text("Longest Streak")
            //                        .font(.headline)
            //                        .foregroundColor(.white.opacity(0.7))
            //                    Text("\(longestStreak) Days")
            //                        .font(.title2)
            //                        .fontWeight(.semibold)
            //                        .foregroundColor(.white)
            //                }
            //
            //                Spacer()
            //
            //            }
            //            .padding(.top, 10)
            
            StreakCalendarView(therapySessions: Array(sessions), therapyType: therapyType)
                .padding(.top, 10)
                .padding(.bottom, 10)
            
            Divider()
                .background(Color.white)
            
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
            guard let dateString = session.date,
                  let sessionDate = dateFormatter.date(from: dateString) else {
                return false
            }
            
            let sessionDay = Calendar.current.startOfDay(for: sessionDate)
            let checkDay = Calendar.current.startOfDay(for: date)
            
            return Calendar.current.isDate(sessionDay, inSameDayAs: checkDay) && session.therapyType == therapyType.rawValue
        })
    }
    
    private func getDaysArray() -> [String] {
        let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let today = Calendar.current.component(.weekday, from: Date())
        var lastSevenDays = [String]()
        
        for i in 0..<7 {
            let index = (today - i - 1 + 7) % 7
            lastSevenDays.insert(daysInWeek[index], at: 0)
        }
        
        return lastSevenDays
    }
    
    private func dateFromDay(day: String, daysInWeek: [String]) -> Date {
        let today = Calendar.current.component(.weekday, from: Date())
        let index = (7 + today - daysInWeek.firstIndex(of: day)!) % 7
        let date = Calendar.current.date(byAdding: .day, value: -index, to: Date())
        
        return date!
    }
    
    private func isDateInFuture(date: Date) -> Bool {
        return date > Date()
    }
}



extension TimeFrame {
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


