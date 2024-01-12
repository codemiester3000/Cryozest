import SwiftUI

class SleepComparisonDataModel: ObservableObject {
    
    var timeFrame: TimeFrame {
        didSet {
            fetchSleepData()
        }
    }
    
    var sessions: FetchedResults<TherapySessionEntity>
    
    @Published var therapyType: TherapyType {
        didSet {
            fetchSleepData()
        }
    }
    
    @Published var maxValue: CGFloat
    
    @Published var baselineTotalSleep: Double
    @Published var exerciseTotalSleep: Double
    
    @Published var baselineSleepData: NewSleepData {
        didSet {
            maxValue = max(baselineSleepData.total, exerciseSleepData.total)
        }
    }
    
    @Published var exerciseSleepData: NewSleepData {
        didSet {
            maxValue = max(baselineSleepData.total, exerciseSleepData.total)
        }
    }
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.sessions = sessions
        self.timeFrame = timeFrame
        self.therapyType = therapyType
        self.maxValue = 0.0
        
        print("Owen here \n\n\n")
        print("sessions: ", sessions)
        print("timeFrame: ", timeFrame)
        print("therapyType: ", therapyType)
        print("\n\n\n")
        
        baselineTotalSleep = 0.0
        exerciseTotalSleep = 0.0
        
        baselineSleepData = NewSleepData(rem: 0, deep: 0, total: 0)
        exerciseSleepData = NewSleepData(rem: 0, deep: 0, total: 0)
        
        fetchSleepData()
    }
    
    private func fetchSleepData() {
        // Fetch baseline sleep days (off days)
        let baselineDates = DateUtils.shared.datesWithoutTherapySessions(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        HealthKitManager.shared.fetchAverageSleepStatisticsForDays(days: baselineDates) { averageTotalSleep, averageREMSleep, averageDeepSleep in
            print("baseline Total Sleep: \(averageTotalSleep) hrs")
            print("baseline REM Sleep: \(averageREMSleep) hrs")
            print("baseline Deep Sleep: \(averageDeepSleep) hrs")
            
            DispatchQueue.main.async {
                self.baselineSleepData.rem = 2.0 // averageREMSleep
                self.baselineSleepData.total = averageTotalSleep
                self.baselineSleepData.deep = 5.0 //averageDeepSleep
            }
        }
        
        // Fetch sleep data for therapy days
        let completedSessionDates = DateUtils.shared.completedSessionDatesForTimeFrame(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        print("fetchSleepForExcerciseDays ", completedSessionDates)
        
        HealthKitManager.shared.fetchAverageSleepStatisticsForDays(days: completedSessionDates) { averageTotalSleep, averageREMSleep, averageDeepSleep in
            print("Average Total Sleep: \(averageTotalSleep) hrs")
            print("Average REM Sleep: \(averageREMSleep) hrs")
            print("Average Deep Sleep: \(averageDeepSleep) hrs")
            
            DispatchQueue.main.async {
                self.exerciseSleepData.rem = 3.0 //averageREMSleep
                self.exerciseSleepData.total = 4.0 // averageTotalSleep
                self.exerciseSleepData.deep = 1.0 // averageDeepSleep
            }
        }
    }
}

struct NewSleepData {
    //var awake: TimeInterval
    var rem: TimeInterval
    // var core: TimeInterval
    var deep: TimeInterval
    var total: TimeInterval
}

struct SleepComparisonBarGraph: View {
    @ObservedObject var model: SleepComparisonDataModel
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ComparisonBarView(baselineValue: model.baselineSleepData.total, excerciseValue: model.exerciseSleepData.total, color: model.therapyType.color, maxValue: model.maxValue, label: "Total")
            ComparisonBarView(baselineValue: model.baselineSleepData.rem, excerciseValue:  model.exerciseSleepData.rem, color: model.therapyType.color, maxValue: model.maxValue, label: "REM")
            ComparisonBarView(baselineValue: model.baselineSleepData.deep, excerciseValue:  model.exerciseSleepData.deep,color: model.therapyType.color, maxValue: model.maxValue, label: "Deep")
        }
        .padding()
    }
}

struct ComparisonBarView: View {
    var baselineValue: CGFloat
    var excerciseValue: CGFloat
    var color: Color
    var maxValue: CGFloat
    var label: String
    
    let multiplier = 12.0
    
    private var baselineHeight: CGFloat {
        min(baselineValue, maxValue)
    }
    
    private var excerciseHeight: CGFloat {
        min(excerciseValue, maxValue)
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                // Invisible background frame to enforce consistent maximum height
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: maxValue * multiplier)
                
                if baselineHeight >= excerciseHeight {
                    // Baseline rectangle (gray) is shorter or equal, so it goes in front
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: baselineHeight * multiplier)
                    Rectangle()
                        .fill(color)
                        .frame(height: excerciseHeight * multiplier)
                } else {
                    // Excercise rectangle (blue) is shorter, so it goes in front
                    Rectangle()
                        .fill(color)
                        .frame(height: excerciseHeight * multiplier)
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: baselineHeight * multiplier)
                }
            }
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(String(format: "%.1f hrs", excerciseValue))
                .font(.caption)
                .foregroundColor(color)
            
            Text(String(format: "%.1f hrs", baselineValue))
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}



