import SwiftUI
import CoreData

struct AnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>
    
    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    var selectedTherapyTypes: [TherapyType] {
        // Convert the selected therapy types from strings to TherapyType values
        if selectedTherapies.isEmpty {
            return Array(TherapyType.allCases.prefix(4))
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }
    
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
                ForEach(selectedTherapyTypes, id: \.self) { therapyType in
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
                                    therapyType.color
                                    : Color(.gray))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 5)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
            .padding(.top, 8)
            
            Picker("Time frame", selection: $selectedTimeFrame) {
                Text("Last 7 days")
                    .tag(TimeFrame.week)
                    .foregroundColor(selectedTimeFrame == .week ? .orange : .primary)
                Text("Last Month")
                    .tag(TimeFrame.month)
                    .foregroundColor(selectedTimeFrame == .month ? .orange : .primary)
                Text("Last Year")
                    .tag(TimeFrame.allTime)
                    .foregroundColor(selectedTimeFrame == .allTime ? .orange : .blue)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 8)
            .padding(.horizontal)
            
            ScrollView {
                AvgHeartRateComparisonView(heartRateViewModel: HeartRateViewModel(therapyType: therapyType, timeFrame: selectedTimeFrame, sessions: sessions))
                
                // HRVAnalysisView()
                
                DurationAnalysisView(
                    totalTime: getTotalTime(for: therapyType),
                    totalSessions: getTotalSessions(for: therapyType),
                    timeFrame: selectedTimeFrame,
                    therapyType: self.therapyType,
                    currentStreak: getCurrentStreak(for: therapyType),
                    longestStreak: getLongestStreak(for: therapyType), // Assuming you have a function to get the longest streak
                    sessions: sessions
                )
                .padding(.horizontal)
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
        .onAppear {
            if let firstTherapy = selectedTherapies.first, let therapyType = TherapyType(rawValue: firstTherapy.therapyType ?? "") {
                self.therapyType = therapyType
            }
        }
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
            return "Last Year"
        }
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
        HStack() {
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
