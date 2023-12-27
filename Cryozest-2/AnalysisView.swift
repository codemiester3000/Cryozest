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
        VStack {
            ScrollView {
                HStack {
                    Text("Analysis")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .bold()
                        .padding(.top, 36)
                        .padding(.leading, 24)
                    
                    Spacer()
                }
                
                TherapyTypeGrid(therapyTypeSelection: therapyTypeSelection, selectedTherapyTypes: selectedTherapyTypes)
                    .padding(.bottom, 16)
                
                Divider()
                    .background(Color.black.opacity(0.8))
                    .padding(.bottom, 8)
                
                Picker("Time frame", selection: $selectedTimeFrame) {
                    Text("Last Week")
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
                //.padding(.bottom, 16)
                .padding(.horizontal)
                
                Divider()
                    .background(Color.black.opacity(0.8))
                    .padding(.vertical, 8)
                
                MetricsHighlightsView(model: MetricsHighlightsViewModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions))
                
                Divider()
                    .background(Color.black.opacity(0.8))
                    .padding(.vertical, 8)
                
                DurationAnalysisView(viewModel: DurationAnalysisViewModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions)).padding(.horizontal)
                
                Divider().background(Color.black.opacity(0.8)).padding(.vertical, 8)
                
                AvgHeartRateComparisonView(heartRateViewModel: HeartRateViewModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions))
                
                Divider().background(Color.black.opacity(0.8)).padding(.vertical, 8)
                
                RecoveryAnalysisView(viewModel: SleepViewModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions))
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
            return "Last Week"
        case .month:
            return "Last Month"
        case .allTime:
            return "Last Year"
        }
    }
}
