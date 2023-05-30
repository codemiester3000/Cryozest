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
                                    : Color.gray)
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
                         totalSessions: getTotalSessions(for: therapyType))
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
            } else {
                streakStarted = true
                currentStreak = 1
            }
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
    
    var body: some View {
        VStack {
            
            
            
            HStack {
                
                //                Image(systemName: therapyType.icon)
                //                    .foregroundColor(therapyType.rawValue == TherapyType.drySauna.rawValue || therapyType.rawValue == TherapyType.hotYoga.rawValue ? .orange : .blue)
                //                    .font(.title)
                Text(therapyType.rawValue)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)
                
                
            }
            
            
            
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 24))
                Text("Current Streak: \(currentStreak) Days")
                    .foregroundColor(.white)
                    .font(.callout)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Longest Streak")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(longestStreak) Days")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Total Sessions")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(totalSessions)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 10)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Time")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(Int(totalTime / 60)) mins")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.top, 10)
        }
        .padding()
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

