import SwiftUI

class SleepComparisonDataModel: ObservableObject {
    
    var timeFrame: TimeFrame {
        didSet {
            fetchSleepData()
        }
    }
    @Published var therapyType: TherapyType {
        didSet {
            fetchSleepData()
        }
    }
    
    var sessions: FetchedResults<TherapySessionEntity>
    
    @Published var baselineTotalSleep: Double
    @Published var exerciseTotalSleep: Double
    
    @Published var baselineSleepData: NewSleepData
    @Published var exerciseSleepData: NewSleepData
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.sessions = sessions
        self.timeFrame = timeFrame
        self.therapyType = therapyType
        
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
                self.baselineSleepData.rem = averageREMSleep
                self.baselineSleepData.total = averageTotalSleep
                self.baselineSleepData.deep = averageDeepSleep
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
                self.exerciseSleepData.rem = averageREMSleep
                self.exerciseSleepData.total = averageTotalSleep
                self.exerciseSleepData.deep = averageDeepSleep
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
    
    let maxValue = 100.0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ComparisonBarView(baselineValue: model.baselineSleepData.total, excerciseValue: model.exerciseSleepData.total, maxValue: maxValue, label: "Total")
            ComparisonBarView(baselineValue: model.baselineSleepData.rem, excerciseValue:  model.exerciseSleepData.rem, maxValue: maxValue, label: "REM")
            ComparisonBarView(baselineValue: model.baselineSleepData.deep, excerciseValue:  model.exerciseSleepData.deep, maxValue: maxValue, label: "Deep")
        }
        .padding()
    }
}

struct ComparisonBarView: View {
    var baselineValue: CGFloat
    var excerciseValue: CGFloat
    
    var maxValue: CGFloat
    var label: String
    
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
                    .frame(height: maxValue)
                
                // Red bar
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: baselineHeight)
                
                // Blue bar
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: excerciseHeight)
            }
            
            // Label
            Text("\(baselineValue)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}


