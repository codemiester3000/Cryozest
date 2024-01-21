import SwiftUI
import CoreData

struct AnalysisView: View {
    
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    
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
            return [.drySauna, .weightTraining, .coldPlunge, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }
    
    let healthKitManager = HealthKitManager.shared
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var selectedTimeFrame: TimeFrame = .week
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"
        return df
    }()
    
    init(therapyTypeSelection: TherapyTypeSelection) {
        self.therapyTypeSelection = therapyTypeSelection
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    HStack {
                        Text("Metrics Comparisons")
                            .font(.system(size: 24, weight: .regular, design: .default))
                            .foregroundColor(.white)
                            .bold()
                            .padding(.leading, 24)
                        
                        Spacer()
                        
                        NavigationLink(destination: TherapyTypeSelectionView()) {
                            SettingsIconView(settingsColor: therapyTypeSelection.selectedTherapyType.color)
                                .padding(.trailing, 25)
                        }
                    }
                    .padding(.top, 36)
                    
                    TherapyTypeGrid(therapyTypeSelection: therapyTypeSelection, selectedTherapyTypes: selectedTherapyTypes)
                        .padding(.bottom, 16)
                    
                    CustomPicker(selectedTimeFrame: $selectedTimeFrame)
                    
                    DurationAnalysisView(viewModel: DurationAnalysisViewModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions))
                        .padding(.horizontal)
                        .padding(.top)
                    
                    Divider().background(Color.white.opacity(0.8)).padding(.vertical, 8)
                    
                    RecoveryAnalysisView(viewModel: SleepViewModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions))
                        .padding(.bottom)
                    
                    Divider().background(Color.white.opacity(0.8)).padding(.vertical, 8)
                    
                    WakingAnalysisView(model: WakingAnalysisDataModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        }
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

enum TimeFrame: CaseIterable {
    case week, month, allTime
    
    func displayString() -> String {
        switch self {
        case .week:
            return "Last Week"
        case .month:
            return "Last Month"
        case .allTime:
            return "Last Year"
        }
    }
    
    func presentDisplayString() -> String {
        switch self {
        case .week:
            return "this week"
        case .month:
            return "this month"
        case .allTime:
            return "this year"
        }
    }
    
    func numberOfDays() -> Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 30
        case .allTime:
            return 365
        }
    }
}

//struct CustomPicker: View {
//    @Binding var selectedTimeFrame: TimeFrame
//
//    var body: some View {
//        HStack {
//            ForEach(timeFrames, id: \.self) { timeFrame in
//                Text(timeFrame.displayText)
//                    .foregroundColor(selectedTimeFrame == timeFrame ? .orange : .white)
//                    .padding(.vertical, 10)
//                    .padding(.horizontal, 20)
//                    .background(selectedTimeFrame == timeFrame ? Color.orange.opacity(0.2) : Color.clear)
//                    .cornerRadius(10)
//                    .onTapGesture {
//                        self.selectedTimeFrame = timeFrame
//                    }
//            }
//        }
//        .padding(.horizontal)
//        .background(Color.black)
//        .cornerRadius(15)
//    }
//}
