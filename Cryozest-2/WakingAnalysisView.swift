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
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.sessions = sessions
        self.timeFrame = timeFrame
        self.therapyType = therapyType
        
        baselineRestingHR = 0.0
        exerciseRestingHR = 0.0
        
        // TODO: WHY IS THIS CAUSING A CRASH
        fetchData()
    }
    
    private func fetchData() {
        
        print("timeFrame: ", timeFrame)
        
        let baselineDates = DateUtils.shared.datesWithoutTherapySessions(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        HealthKitManager.shared.fetchWakingStatisticsForDays(days: baselineDates) { avgHeartRate, avgCalories, avgSteps in
            
            DispatchQueue.main.async {
                self.baselineRestingHR = 75 //avgHeartRate
            }
        }
//        
//        let completedSessionDates = DateUtils.shared.completedSessionDatesForTimeFrame(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
//        
//        HealthKitManager.shared.fetchWakingStatisticsForDays(days: completedSessionDates) { avgHeartRate, avgCalories, avgSteps in
//            
//            DispatchQueue.main.async {
//                self.exerciseRestingHR = 50 //avgHeartRate
//            }
//        }
    }
}

struct WakingAnalysisView: View {
    @ObservedObject var model: WakingAnalysisDataModel
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Awake")
                        .font(.system(size: 24, weight: .regular, design: .default))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    Spacer()
                    
                    Text(model.therapyType.displayName(managedObjectContext))
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(model.therapyType.color)
                        .cornerRadius(8)
                }
                
                HStack {
                    Spacer()
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
                }
            }
            .padding(.horizontal)
            
            ComparisonView(
                symbolName: "arrow.down.heart",
                title: "RHR",
                baselineValue: "\(model.baselineRestingHR ?? 0)",
                exerciseValue: "\(model.baselineRestingHR ?? 0)",
                unit: "bpm"
            )
        }
    }
}


struct ComparisonView: View {
    var symbolName: String
    var title: String
    var baselineValue: String
    var exerciseValue: String
    var unit: String

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
                        .padding(.bottom, 2)
                }

                Spacer()

                HStack(alignment: .bottom) {
                    Text(exerciseValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 2)
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



