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
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                // Section Title
                Text("Daily Metrics")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Text("baseline")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    Spacer()
                    Text("\(model.therapyType.displayName(managedObjectContext)) days")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(model.therapyType.color.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(model.therapyType.color.opacity(0.6), lineWidth: 1)
                                )
                        )
                }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: symbolName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Baseline")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(baselineValue)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(unit)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.bottom, 3)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("With Therapy")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(exerciseValue)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(color)
                        Text(unit)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.bottom, 3)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}



