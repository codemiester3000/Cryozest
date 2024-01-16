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
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var body: some View {
        VStack(alignment: .leading) {
            BarGraphView(
                title: "Sleeping Resting Heart Rate",
                baselineValue: model.baselineRestingHeartRate,
                exerciseValue: model.exerciseRestingHeartRate,
                baselineLabel: "\(model.baselineRestingHeartRate.isFinite ? Int(model.baselineRestingHeartRate) : 0) bpm",
                exerciseLabel: "\(model.exerciseRestingHeartRate.isFinite ? Int(model.exerciseRestingHeartRate) : 0) bpm",
                barColor: model.therapyType.color
            )
            .padding(.bottom)
            
            BarGraphView(
                title: "Sleeping Heart Rate Variability",
                baselineValue: model.baselineRestingHRV,
                exerciseValue: model.exerciseRestingHRV,
                baselineLabel: "\(model.baselineRestingHRV.isFinite ? Int(model.baselineRestingHRV) : 0) bpm",
                exerciseLabel: "\(model.exerciseRestingHRV.isFinite ? Int(model.exerciseRestingHRV) : 0) bpm",
                barColor: model.therapyType.color
            )
            .padding(.bottom)
            
            
            
            ParagraphText("RHR",
                          percentChange: calculatePercentChange(baseline: model.baselineRestingHeartRate,
                                                                exercise: model.exerciseRestingHeartRate) ?? 0,
                          therapyTypeDisplayName: model.therapyType.displayName(managedObjectContext))

        
                   ParagraphText("HRV",
                                 percentChange: calculatePercentChange(baseline: model.baselineRestingHRV,
                                                                       exercise: model.exerciseRestingHRV) ?? 0,
                                 therapyTypeDisplayName: model.therapyType.displayName(managedObjectContext))
             
        }
    }
    
    private func calculatePercentChange(baseline: Double, exercise: Double) -> CGFloat? {
            if baseline != 0 {
                return CGFloat((exercise - baseline) / baseline * 100)
            }
            return nil
        }
    
    
    @ViewBuilder
    private func ParagraphText(_ metricType: String, percentChange: CGFloat, therapyTypeDisplayName: String) -> some View {
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
            
            + Text("in \(metricType) on ")
                .font(.system(size: 12))
                .foregroundColor(.white)
            
            + Text("\(therapyTypeDisplayName) days")
                .font(.system(size: 12))
                .foregroundColor(model.therapyType.color)
        }
        .padding(.bottom, 6)
    }

    private func changeIndicator(for percentChange: CGFloat) -> (symbol: String, color: Color) {
        if percentChange == 0 {
        return ("↑", .green)
        } else {
        return ("↓", .red)
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
    
    private let maxBarWidth: CGFloat = 200  // Maximum width of the bar
    private let maxValue: Double = 100 // This should be your maximum scale value

    
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
                      .frame(width: CGFloat(baselineValue / maxValue) * maxBarWidth, height: 20)
                      .cornerRadius(6.0)
                  
                  Text(baselineLabel)
                      .font(.footnote)
                      .foregroundColor(.white)
              }
              
              // Exercise Bar with Label
              HStack {
                  Rectangle()
                      .fill(LinearGradient(gradient: Gradient(colors: [barColor.opacity(0.6), barColor.opacity(0.9)]), startPoint: .leading, endPoint: .trailing))
                      .frame(width: CGFloat(exerciseValue / maxValue) * maxBarWidth, height: 20)
                      .cornerRadius(6.0)
                  
                  Text(exerciseLabel)
                      .font(.footnote)
                      .foregroundColor(.white)
              }
          }
          .onAppear {
              // Trigger any necessary animations when the view appears
              withAnimation(.linear(duration: 3.0)) {
                  // Your animation code, if needed
              }
          }
      }
  }
