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
        
        HealthKitManager.shared.fetchAverageSleepStatisticsForDays(days: baselineDates) { averageTotalSleep, averageREMSleep, averageDeepSleep, averageCoreSleep in
            print("baseline Total Sleep: \(averageTotalSleep) hrs")
            print("baseline REM Sleep: \(averageREMSleep) hrs")
            print("baseline Deep Sleep: \(averageDeepSleep) hrs")
            
            DispatchQueue.main.async {
                self.baselineSleepData.rem = averageREMSleep
                self.baselineSleepData.total = averageTotalSleep
                self.baselineSleepData.deep = averageDeepSleep
                
//                self.baselineSleepData.rem = 3.0 // averageREMSleep
//                self.baselineSleepData.total = 8.0 // averageTotalSleep
//                self.baselineSleepData.deep = 6.0 // averageDeepSleep
            }
        }
        
        // Fetch sleep data for therapy days
        let completedSessionDates = DateUtils.shared.completedSessionDatesForTimeFrame(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        print("fetchSleepForExcerciseDays ", completedSessionDates)
        
        HealthKitManager.shared.fetchAverageSleepStatisticsForDays(days: completedSessionDates) { averageTotalSleep, averageREMSleep, averageDeepSleep, averageCoreSleep in
            print("Average Total Sleep: \(averageTotalSleep) hrs")
            print("Average REM Sleep: \(averageREMSleep) hrs")
            print("Average Deep Sleep: \(averageDeepSleep) hrs")
            
            DispatchQueue.main.async {
                self.exerciseSleepData.rem = averageREMSleep
                self.exerciseSleepData.total = averageTotalSleep
                self.exerciseSleepData.deep = averageDeepSleep
                
//                self.exerciseSleepData.rem = 7.0 // averageREMSleep
//                self.exerciseSleepData.total = 10.0 // averageTotalSleep
//                self.exerciseSleepData.deep = 5.0 // averageDeepSleep
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
            
            ParagraphExplanation(model: model)
            
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

struct ParagraphExplanation: View {
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @ObservedObject var model: SleepComparisonDataModel
    
    var totalSleepPercentChange: CGFloat {
        guard model.baselineSleepData.total != 0 else { return 0 }
        return ((model.exerciseSleepData.total - model.baselineSleepData.total) / model.baselineSleepData.total) * 100
    }
    
    var remSleepPercentChange: CGFloat {
        guard model.baselineSleepData.rem != 0 else { return 0 }
        return ((model.exerciseSleepData.rem - model.baselineSleepData.rem) / model.baselineSleepData.rem) * 100
    }
    
    var deepSleepPercentChange: CGFloat {
        guard model.baselineSleepData.deep != 0 else { return 0 }
        return ((model.exerciseSleepData.deep - model.baselineSleepData.deep) / model.baselineSleepData.deep) * 100
    }
    
    private func changeIndicator(for percentChange: CGFloat) -> (color: Color, symbol: String) {
        if percentChange > 0 {
            return (Color.green, "↑")
        } else if percentChange < 0 {
            return (Color.red, "↓")
        } else {
            return (Color.gray, "")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ParagraphText("total sleep", percentChange: totalSleepPercentChange)
            ParagraphText("REM sleep", percentChange: remSleepPercentChange)
            ParagraphText("deep sleep", percentChange: deepSleepPercentChange)
        }
    }

    @ViewBuilder
    private func ParagraphText(_ sleepType: String, percentChange: CGFloat) -> some View {
        let indicator = changeIndicator(for: percentChange)
        let percentChangeText = String(format: "%.1f", abs(percentChange))
        let changeDescription = percentChange >= 0 ? "increase" : "decrease"
        
        HStack(spacing: 2) {
            Text(indicator.symbol)
                .font(.system(size: 12))
                .foregroundColor(indicator.color)

            Text("You saw a ")
                .font(.system(size: 12))
                .foregroundColor(.white)
            
            + Text("\(percentChangeText)% ")
                .font(.system(size: 12))
                .foregroundColor(indicator.color)
                .fontWeight(.bold)
            
            + Text("\(changeDescription) ")
                .font(.system(size: 12))
                .foregroundColor(indicator.color)
                .fontWeight(.bold)
            
            + Text("in \(sleepType) on ")
                .font(.system(size: 12))
                .foregroundColor(.white)
            
            + Text("\(model.therapyType.displayName(managedObjectContext)) days")
                .font(.system(size: 12))
                .foregroundColor(model.therapyType.color)
        }
        .padding(.bottom, 6)
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
            gradient: Gradient(colors: [Color(white: 0.8), Color(white: 0.6)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var exerciseGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [color.opacity(0.8), color]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
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
                Text(String(format: "%.1f hrs", exerciseValue))
                    .font(.caption)
                    .foregroundColor(color)

                Text(String(format: "%.1f hrs", baselineValue))
                    .font(.caption)
                    .foregroundColor(.white)
                
//                Text(String(format: "%.1f%%", percentChange) + (percentChange >= 0.0 ? " ↑" : " ↓"))
//                    .font(.caption)
//                    .foregroundColor(percentChange >= 0.0 ? .green : .red)
//                    .padding(.top)
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



