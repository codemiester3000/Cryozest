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
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 12) {
                ComparisonBarView(baselineValue: model.baselineSleepData.total, exerciseValue: model.exerciseSleepData.total, color: model.therapyType.color, maxValue: model.maxValue, label: "Total")
                ComparisonBarView(baselineValue: model.baselineSleepData.rem, exerciseValue:  model.exerciseSleepData.rem, color: model.therapyType.color, maxValue: model.maxValue, label: "REM")
                ComparisonBarView(baselineValue: model.baselineSleepData.deep, exerciseValue:  model.exerciseSleepData.deep,color: model.therapyType.color, maxValue: model.maxValue, label: "Deep")
            }
            .padding()
            
            VStack {
                HStack {
                    Text("Avg Sleep Duration")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    
                    Image(systemName: "moon.fill")
                        .foregroundColor(model.therapyType.color)
                        .padding(.trailing, 10)
                }
                HStack {
                    HStack {
                        Text("\(model.therapyType.displayName(managedObjectContext)) days")
                            .font(.footnote)
                            .foregroundColor(.white)
                        
                    }
                    Spacer()
                    Text((model.exerciseSleepData.total != 0 ? String(format: "%.1f", model.exerciseSleepData.total) + " Hrs" : "N/A"))
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.trailing, 10)
                }
                .padding(.vertical, 5)
                HStack {
                    HStack {
                        
                        Text("baseline")
                            .font(.footnote)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text((model.baselineSleepData.total != 0 ? String(format: "%.1f", model.baselineSleepData.total) + " Hrs" : "N/A"))
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.trailing, 10)
                }
            }
            .padding(.top)
        }
    }
}

struct ComparisonBarView: View {
    var baselineValue: CGFloat
    var exerciseValue: CGFloat
    var color: Color
    var maxValue: CGFloat
    var label: String

    let multiplier = 12.0
    
    private var percentChange: CGFloat {
        ((exerciseValue - baselineValue) / baselineValue) * 100
    }

    private var baselineHeight: CGFloat {
        min(baselineValue, maxValue)
    }

    private var exerciseHeight: CGFloat {
        min(exerciseValue, maxValue)
    }

    private var baselineGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.gray.opacity(0.6), .gray]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var exerciseGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [color.opacity(0.6), color]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack {
            Text(String(format: "%.1f%%", percentChange) + (percentChange >= 0.0 ? " ↑" : " ↓"))
                .font(.caption)
                .foregroundColor(percentChange >= 0.0 ? .green : .red)
            
            ZStack(alignment: .bottom) {
                // Invisible background frame to enforce consistent maximum height
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: maxValue * multiplier)

                if baselineHeight >= exerciseHeight {
                    BarView(height: baselineHeight, gradient: baselineGradient)
                    BarView(height: exerciseHeight, gradient: exerciseGradient)
                } else {
                    BarView(height: exerciseHeight, gradient: exerciseGradient)
                    BarView(height: baselineHeight, gradient: baselineGradient)
                }
            }

            Group {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)

                Text(String(format: "%.1f hrs", exerciseValue))
                    .font(.caption)
                    .foregroundColor(color)

                Text(String(format: "%.1f hrs", baselineValue))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct BarView: View {
    var height: CGFloat
    var gradient: LinearGradient
    let multiplier: CGFloat = 12.0

    var body: some View {
        Rectangle()
            .fill(gradient)
            .frame(height: height * multiplier)
            .cornerRadius(10)
            .animation(.easeInOut(duration: 0.5))
    }
}



