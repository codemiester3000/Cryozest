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
    
    @Published var baselineRespiratoryRate: Double
    @Published var exerciseRespiratoryRate: Double
    @Published var baselineSPO2: Double
    @Published var exerciseSPO2: Double
    
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.sessions = sessions
        self.timeFrame = timeFrame
        self.therapyType = therapyType
        
        baselineRestingHeartRate = 0.0
        exerciseRestingHeartRate = 0.0
        baselineRestingHRV = 0.0
        exerciseRestingHRV = 0.0
        baselineRespiratoryRate = 0.0
        exerciseRespiratoryRate = 0.0
        baselineSPO2 = 0.0
        exerciseSPO2 = 0.0
        
        fetchSleepVitalsData()
    }
    
    private func fetchSleepVitalsData() {
        let baselineDates = DateUtils.shared.datesWithoutTherapySessions(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        HealthKitManager.shared.fetchAverageSleepVitalsForDays(days: baselineDates) { averageHeartRate, averageHRV in
            DispatchQueue.main.async {
                self.baselineRestingHeartRate = averageHeartRate
                self.baselineRestingHRV = averageHRV
            }
        }
        HealthKitManager.shared.fetchAverageRespiratoryRateAndSPO2ForDays(days: baselineDates) { averageRespiratoryRate, averageSPO2 in
            DispatchQueue.main.async {
                self.baselineRespiratoryRate = averageRespiratoryRate
                self.baselineSPO2 = averageSPO2
            }
        }
        
        let therapySessionDates = DateUtils.shared.completedSessionDatesForTimeFrame(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        
        HealthKitManager.shared.fetchAverageRespiratoryRateAndSPO2ForDays(days: therapySessionDates) { averageRespiratoryRate, averageSPO2 in
            DispatchQueue.main.async {
                self.exerciseRespiratoryRate = averageRespiratoryRate
                self.exerciseSPO2 = averageSPO2
            }
        }
        
        
        
        HealthKitManager.shared.fetchAverageSleepVitalsForDays(days: therapySessionDates) { averageHeartRate, averageHRV in
            DispatchQueue.main.async {
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
            CenteredDivider().padding(.bottom, 8)
            
            BarGraphView(
                title: "Sleeping Resting Heart Rate",
                baselineValue: model.baselineRestingHeartRate,
                exerciseValue: model.exerciseRestingHeartRate,
                baselineLabel: "\(model.baselineRestingHeartRate.isFinite ? Int(model.baselineRestingHeartRate) : 0) bpm",
                exerciseLabel: "\(model.exerciseRestingHeartRate.isFinite ? Int(model.exerciseRestingHeartRate) : 0) bpm",
                barColor: model.therapyType.color,
                upArrow: true,
                isGreen: true
            )
            .padding(.bottom)
            
            CenteredDivider().padding(.bottom, 8)
            
            BarGraphView(
                title: "Sleeping Heart Rate Variability",
                baselineValue: model.baselineRestingHRV,
                exerciseValue: model.exerciseRestingHRV,
                baselineLabel: "\(model.baselineRestingHRV.isFinite ? Int(model.baselineRestingHRV) : 0) bpm",
                exerciseLabel: "\(model.exerciseRestingHRV.isFinite ? Int(model.exerciseRestingHRV) : 0) bpm",
                barColor: model.therapyType.color,
                upArrow: true,
                isGreen: true
            )
            .padding(.bottom)
            
            CenteredDivider()
                .padding(.bottom, 4)
            
            // Respiratory Rate Graph
            BarGraphView(
                title: "Sleeping Respiratory Rate",
                baselineValue: model.baselineRespiratoryRate,
                exerciseValue: model.exerciseRespiratoryRate,
                baselineLabel: "\(Int(model.baselineRespiratoryRate)) br/min",
                exerciseLabel: "\(Int(model.exerciseRespiratoryRate)) br/min",
                barColor: model.therapyType.color,
                upArrow: true,
                isGreen: true
            )
            .padding(.bottom)
            
            CenteredDivider().padding(.bottom, 4)
            
            // SPO2 Graph
            BarGraphView(
                title: "Sleeping SPO2",
                baselineValue: model.baselineSPO2 * 100,
                exerciseValue: model.exerciseSPO2 * 100,
                baselineLabel: "\(Int(model.baselineSPO2 * 100))%",
                exerciseLabel: "\(Int(model.exerciseSPO2 * 100))%",
                barColor: model.therapyType.color,
                upArrow: true,
                isGreen: true
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
            
            ParagraphText("Respiratory Rate",
                          percentChange: calculatePercentChange(baseline: model.baselineRespiratoryRate,
                                                                exercise: model.exerciseRespiratoryRate) ?? 0,
                          therapyTypeDisplayName: model.therapyType.displayName(managedObjectContext))
            
            ParagraphText("SPO2",
                          percentChange: calculatePercentChange(baseline: model.baselineSPO2,
                                                                exercise: model.exerciseSPO2) ?? 0,
                          therapyTypeDisplayName: model.therapyType.displayName(managedObjectContext))
            
            VitalsGaugeView(model: model)
                .padding(.bottom)
            
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
    var upArrow: Bool
    var isGreen: Bool
    
    private let maxBarWidth: CGFloat = 200  // Maximum width of the bar
    private let maxValue: Double = 100 // This should be your maximum scale value
    
    
    @State private var baselineBarWidth: CGFloat = 0
    @State private var exerciseBarWidth: CGFloat = 0
    
    private func isInvalidValues() -> Bool {
        return (baselineValue == 0 || !baselineValue.isFinite) && (exerciseValue == 0 || !exerciseValue.isFinite)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.white)
                
                Image(systemName: upArrow ? "arrow.up" : "arrow.down")
                    .foregroundColor(isGreen ? .green : .red)
            }
            
            // Baseline Bar with Label
            HStack {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5), .gray]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: isInvalidValues() ? 150 : CGFloat(baselineValue / maxValue) * maxBarWidth, height: 20)
                    .cornerRadius(6.0)
                
                Text(baselineLabel)
                    .font(.footnote)
                    .foregroundColor(.white)
            }
            
            // Exercise Bar with Label
            HStack {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [barColor.opacity(0.6), barColor.opacity(0.9)]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: isInvalidValues() ? 150 : CGFloat(exerciseValue / maxValue) * maxBarWidth, height: 20)
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

struct CenteredDivider: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer() // Pushes everything below to the middle
                
                Divider()
                    .frame(width: geometry.size.width * 0.8) // 80% of screen's width
                    .background(Color.white) // Set the color to white
                
                Spacer() // Centers the divider vertically
            }
        }
    }
}

struct GaugeView: View {
    var title: String
    var value: Double
    var inRange: ClosedRange<Double>
    var unit: String
    
    private var normalizedValue: Double {
        // Normalize the value to fit within the gauge scale
        return min(max(value, inRange.lowerBound), inRange.upperBound)
    }
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            Gauge(value: normalizedValue, in: inRange) {
                Text("")
            } currentValueLabel: {
                Text("\(value, specifier: "%.1f")\(unit)")
                    .font(.headline)
            } minimumValueLabel: {
                Text("\(inRange.lowerBound, specifier: "%.0f")")
            } maximumValueLabel: {
                Text("\(inRange.upperBound, specifier: "%.0f")")
            }
            .gaugeStyle(.accessoryLinearCapacity)
        }
    }
}

struct VitalsGaugeView: View {
    @ObservedObject var model: SleepVitalsDataModel
    
    var body: some View {
        VStack {
            // Respiratory Rate Comparison
            Text("Sleeping Respiratory Rate Comparison")
                .font(.headline)
                .padding()
            
            HStack {
                GaugeView(
                    title: "Baseline Days",
                    value: model.baselineRespiratoryRate,
                    inRange: 10...20,  // Adjust the range as appropriate
                    unit: " br/min"
                )
                
                GaugeView(
                    title: "Therapy Days",
                    value: model.exerciseRespiratoryRate,
                    inRange: 10...20,  // Adjust the range as appropriate
                    unit: " br/min"
                )
            }
            
            // SPO2 Comparison
            Text("Sleeping SPO2 Comparison")
                .font(.headline)
                .padding()
            
            HStack {
                GaugeView(
                    title: "Baseline Days",
                    value: model.baselineSPO2 * 100,  // Assuming this value is in decimal format
                    inRange: 90...100,  // Adjust the range as appropriate
                    unit: "%"
                )
                
                GaugeView(
                    title: "Therapy Days",
                    value: model.exerciseSPO2 * 100,  // Assuming this value is in decimal format
                    inRange: 90...100,  // Adjust the range as appropriate
                    unit: "%"
                )
            }
        }
    }
}

