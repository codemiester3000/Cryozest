import SwiftUI

class WakingAnalysisDataModel: ObservableObject {
    var timeFrame: TimeFrame {
        didSet {
            fetchData()
        }
    }
    
    var sessions: FetchedResults<TherapySessionEntity>
    
    @Published var therapyType: TherapyType {
        didSet {
            fetchData()
        }
    }
    
    @Published var baselineRestingHR: CGFloat
    @Published var exerciseRestingHR: CGFloat
    
    @Published var baselineRestingCalories: CGFloat
    @Published var exerciseRestingCalories: CGFloat
    
    @Published var baselineRestingSteps: CGFloat
    @Published var exerciseRestingSteps: CGFloat
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.sessions = sessions
        self.timeFrame = timeFrame
        self.therapyType = therapyType
        
        baselineRestingHR = 0.0
        exerciseRestingHR = 0.0
        
        baselineRestingCalories = 0.0
        exerciseRestingCalories = 0.0
        
        baselineRestingSteps = 0.0
        exerciseRestingSteps = 0.0
        
        fetchData()
    }
    
    private func fetchData() {
        let baselineDates = DateUtils.shared.datesWithoutTherapySessions(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        HealthKitManager.shared.fetchWakingStatisticsForDays(days: baselineDates) { avgHeartRate, avgCalories, avgSteps in
            DispatchQueue.main.async {
                self.baselineRestingHR = avgHeartRate
                self.baselineRestingCalories = avgCalories
                self.baselineRestingSteps = avgSteps
            }
        }
        
        let completedSessionDates = DateUtils.shared.completedSessionDatesForTimeFrame(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        HealthKitManager.shared.fetchWakingStatisticsForDays(days: completedSessionDates) { avgHeartRate, avgCalories, avgSteps in
            
            DispatchQueue.main.async {
                self.exerciseRestingHR = avgHeartRate
                self.exerciseRestingCalories = avgCalories
                self.exerciseRestingSteps = avgSteps
            }
        }
    }
}

struct WakingAnalysisView: View {
    @ObservedObject var model: WakingAnalysisDataModel
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Averages \(model.timeFrame.presentDisplayString())")
                        .font(.system(size: 24, weight: .regular, design: .default))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    Spacer()
                }
                
                HStack {
                    Text("baseline")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color(white: 0.8), Color(white: 0.6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .cornerRadius(8)
                    Spacer()
                    Text("\(model.therapyType.displayName(managedObjectContext)) days")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(model.therapyType.color)
                        .cornerRadius(8)
                }
                .padding(.bottom)
            }
            .padding(.horizontal)
            
            ComparisonView(
                symbolName: "arrow.down.heart",
                title: "RHR",
                baselineValue: "\(Int(model.baselineRestingHR.isFinite ? model.baselineRestingHR : 0))",
                exerciseValue: "\(Int(model.baselineRestingHR.isFinite ? model.baselineRestingHR : 0))",
                unit: "bpm",
                color: model.therapyType.color
            )
            .padding(.bottom)
            
            ComparisonView(
                symbolName: "flame",
                title: "Total Calories",
                baselineValue: "\(Int(model.baselineRestingCalories.isFinite ? model.baselineRestingCalories : 0))",
                exerciseValue: "\(Int(model.exerciseRestingCalories.isFinite ? model.exerciseRestingCalories : 0))",
                unit: "kcal",
                color: model.therapyType.color
            )
            .padding(.bottom)
            
            ComparisonView(
                symbolName: "figure.walk",
                title: "Steps",
                baselineValue: "\(Int(model.baselineRestingSteps.isFinite ? model.baselineRestingSteps : 0))",
                exerciseValue: "\(Int(model.exerciseRestingSteps.isFinite ? model.exerciseRestingSteps : 0))",
                unit: "steps",
                color: model.therapyType.color
            )
            .padding(.bottom)
        }
    }
}


struct ComparisonView: View {
    var symbolName: String
    var title: String
    var baselineValue: String
    var exerciseValue: String
    var unit: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.gray)
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .layoutPriority(1)
                
                Spacer()
                
//                Image(systemName: symbolName)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 15, height: 15)
//                    .foregroundColor(color)
//                Text(title)
//                    .font(.system(size: 16))
//                    .foregroundColor(.white)
//                    .lineLimit(1)
//                    .layoutPriority(1)
            }
            .padding(.bottom, 2)

            HStack {
                HStack(alignment: .bottom) {
                    Text(baselineValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 4)
                }

                Spacer()

                HStack(alignment: .bottom) {
                    Text(exerciseValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 4)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 22)
        .background(Color.black)
        .cornerRadius(8)
        .shadow(radius: 3)
    }
}



