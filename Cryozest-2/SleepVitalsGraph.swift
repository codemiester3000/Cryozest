import SwiftUI

class SleepVitalsDataModel: ObservableObject {
    var timeFrame: TimeFrame {
        didSet {
            fetchSleepVitalsData()
        }
    }
    
    var sessions: FetchedResults<TherapySessionEntity>
    
    @Published var therapyType: TherapyType {
        didSet {
            fetchSleepVitalsData()
        }
    }
    
    // Resting Heart Rate
    @Published var baselineRestingHeartRate: Double
    @Published var exerciseRestingHeartRate: Double
    
    // Resting Heart Rate Variability
    @Published var baselineRestingHRV: Double
    @Published var exerciseRestingHRV: Double
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.sessions = sessions
        self.timeFrame = timeFrame
        self.therapyType = therapyType
        
        baselineRestingHeartRate = 0.0
        exerciseRestingHeartRate = 0.0
        
        baselineRestingHRV = 0.0
        exerciseRestingHRV = 0.0
        
        fetchSleepVitalsData()
    }
    
    private func fetchSleepVitalsData() {
        let baselineDates = DateUtils.shared.datesWithoutTherapySessions(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        HealthKitManager.shared.fetchAverageSleepVitalsForDays(days: baselineDates) { averageHeartRate, averageHRV in
            DispatchQueue.main.async {
                // Update the published properties on the main thread
                self.baselineRestingHeartRate = averageHeartRate
                self.baselineRestingHRV = averageHRV
            }
        }
        
        let completedSessionDates = DateUtils.shared.completedSessionDatesForTimeFrame(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        HealthKitManager.shared.fetchAverageSleepVitalsForDays(days: completedSessionDates) { averageHeartRate, averageHRV in
            DispatchQueue.main.async {
                // Update the published properties on the main thread
                self.exerciseRestingHeartRate = averageHeartRate
                self.exerciseRestingHRV = averageHRV
            }
        }
    }
    
    
    
}

struct SleepVitalsGraph: View {
    @ObservedObject var model: SleepVitalsDataModel
    
    var body: some View {
        VStack(alignment: .leading) {
            BarGraphView(
                title: "Resting Heart Rate",
                baselineValue: model.baselineRestingHeartRate,
                exerciseValue: model.exerciseRestingHeartRate,
                baselineLabel: "\(model.baselineRestingHeartRate.isFinite ? Int(model.baselineRestingHeartRate) : 0) bpm",
                exerciseLabel: "\(model.exerciseRestingHeartRate.isFinite ? Int(model.exerciseRestingHeartRate) : 0) bpm",
                barColor: model.therapyType.color
            )
            .padding(.bottom)
            
            BarGraphView(
                title: "Resting Heart Rate Variability",
                baselineValue: model.baselineRestingHRV,
                exerciseValue: model.exerciseRestingHRV,
                baselineLabel: "\(model.baselineRestingHRV.isFinite ? Int(model.baselineRestingHRV) : 0) bpm",
                exerciseLabel: "\(model.exerciseRestingHRV.isFinite ? Int(model.exerciseRestingHRV) : 0) bpm",
                barColor: model.therapyType.color
            )
            .padding(.bottom)
            
        }
    }
}

struct BarGraphView: View {
    var title: String
    var baselineValue: Double
    var exerciseValue: Double
    var baselineLabel: String
    var exerciseLabel: String
    var barColor: Color
    
    @State private var baselineBarWidth: CGFloat = 0
    @State private var exerciseBarWidth: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.white)
            
            // Baseline Bar with Label
            HStack {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5), .gray]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: baselineBarWidth, height: 20)
                    .cornerRadius(6.0)
                
                Text(baselineLabel)
                    .font(.footnote)
                    .foregroundColor(.white)
            }
            .onChange(of: baselineValue) { newValue in
                withAnimation(.linear(duration: 3.0)) {
                    baselineBarWidth = (baselineValue == 0 && exerciseValue == 0) ? 200 : newValue
                }
            }
            
            // Exercise Bar with Label
            HStack {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [barColor.opacity(0.6), barColor.opacity(0.9)]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: exerciseBarWidth, height: 20)
                    .cornerRadius(6.0)
                
                Text(exerciseLabel)
                    .font(.footnote)
                    .foregroundColor(.white)
            }
            .onChange(of: exerciseValue) { newValue in
                withAnimation(.linear(duration: 3.0)) {
                    exerciseBarWidth = (baselineValue == 0 && exerciseValue == 0) ? 200 : newValue
                }
            }
        }
    }
}


