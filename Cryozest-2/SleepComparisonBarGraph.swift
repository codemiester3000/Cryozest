import SwiftUI

class SleepComparisonDataModel: ObservableObject {
    
    var timeFrame: TimeFrame
    var sessions: FetchedResults<TherapySessionEntity>
    @Published var therapyType: TherapyType
    
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
        
        baselineSleepData = NewSleepData(awake: 0, rem: 0, core: 0, deep: 0)
        exerciseSleepData = NewSleepData(awake: 0, rem: 0, core: 0, deep: 0)
        
        fetchSleepData()
    }
    
    private func fetchSleepData() {
        // Fetch baseline sleep days (off days)
        let baselineDates = DateUtils.shared.datesWithoutTherapySessions(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        HealthKitManager.shared.fetchAverageSleepStatisticsForDays(days: baselineDates) { averageTotalSleep, averageREMSleep, averageDeepSleep in
            print("baseline Total Sleep: \(averageTotalSleep) hrs")
            print("baseline REM Sleep: \(averageREMSleep) hrs")
            print("baseline Deep Sleep: \(averageDeepSleep) hrs")
        }
        
        // Fetch sleep data for therapy days
        let completedSessionDates = DateUtils.shared.completedSessionDatesForTimeFrame(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        print("fetchSleepForExcerciseDays ", completedSessionDates)
        
        HealthKitManager.shared.fetchAverageSleepStatisticsForDays(days: completedSessionDates) { averageTotalSleep, averageREMSleep, averageDeepSleep in
            print("Average Total Sleep: \(averageTotalSleep) hrs")
            print("Average REM Sleep: \(averageREMSleep) hrs")
            print("Average Deep Sleep: \(averageDeepSleep) hrs")
        }
    }
}

struct NewSleepData {
    var awake: TimeInterval
    var rem: TimeInterval
    var core: TimeInterval
    var deep: TimeInterval
}

struct SleepComparisonBarGraph: View {
    @ObservedObject var model: SleepComparisonDataModel
    
    let maxValue = 100.0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ComparisonBarView(redValueHeightFraction: 0.6, blueValueHeightFraction: 0.4, maxValue: maxValue, label: "Awake")
            ComparisonBarView(redValueHeightFraction: 0.7, blueValueHeightFraction: 0.5, maxValue: maxValue, label: "REM")
            ComparisonBarView(redValueHeightFraction: 0.5, blueValueHeightFraction: 0.8, maxValue: maxValue, label: "Core")
            ComparisonBarView(redValueHeightFraction: 0.4, blueValueHeightFraction: 0.7, maxValue: maxValue, label: "Deep")
        }
        .padding()
    }
}

struct ComparisonBarView: View {
    var redValueHeightFraction: CGFloat
    var blueValueHeightFraction: CGFloat
    var maxValue: CGFloat
    var label: String

    private var redBarHeight: CGFloat {
        min(maxValue * redValueHeightFraction, maxValue)
    }

    private var blueBarHeight: CGFloat {
        min(maxValue * blueValueHeightFraction, maxValue)
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
                    .fill(Color.red)
                    .frame(height: redBarHeight)

                // Blue bar
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: blueBarHeight)
            }

            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}


