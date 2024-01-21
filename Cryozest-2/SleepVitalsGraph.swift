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

enum SleepVitalMetric: String, CaseIterable {
    case RestingHeartRate = "RHR"
    case HeartRateVariability = "HRV"
    case RespiratoryRate = "Resp Rate"
    case SP02 = "SPO2"
    
    var displayTitle: String {
        return self.rawValue
    }
}


struct SleepVitalsGraph: View {
    @ObservedObject var model: SleepVitalsDataModel
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var selectedMetric: SleepVitalMetric = .RestingHeartRate
    
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            
            HStack {
                Spacer()
                CustomMetricsPicker(selectedMetric: $selectedMetric)
                Spacer()
            }
            .padding(.top)
            
            switch selectedMetric {
            case .RestingHeartRate:
                BarGraphView(
                    title: "Sleeping Resting Heart Rate",
                    baselineValue: model.baselineRestingHeartRate.isFinite ? model.baselineRestingHeartRate : 0,
                    exerciseValue: model.exerciseRestingHeartRate.isFinite ? model.exerciseRestingHeartRate : 0,
                    baselineLabel: "\(model.baselineRestingHeartRate.isFinite ? Int(model.baselineRestingHeartRate) : 0) bpm",
                    exerciseLabel: "\(model.exerciseRestingHeartRate.isFinite ? Int(model.exerciseRestingHeartRate) : 0) bpm",
                    barColor: model.therapyType.color
                )
                
                ParagraphText(SleepVitalMetric.RestingHeartRate,
                              percentChange: calculatePercentChange(baseline: model.baselineRestingHeartRate,
                                                                    exercise: model.exerciseRestingHeartRate) ?? 0,
                              therapyTypeDisplayName: model.therapyType.displayName(managedObjectContext))
                .padding(.leading)
                
            case .HeartRateVariability:
                BarGraphView(
                    title: "Sleeping Heart Rate Variability",
                    baselineValue: model.baselineRestingHRV.isFinite ? model.baselineRestingHRV : 0,
                    exerciseValue: model.exerciseRestingHRV.isFinite ? model.exerciseRestingHRV : 0,
                    baselineLabel: "\(model.baselineRestingHRV.isFinite ? Int(model.baselineRestingHRV) : 0) bpm",
                    exerciseLabel: "\(model.exerciseRestingHRV.isFinite ? Int(model.exerciseRestingHRV) : 0) bpm",
                    barColor: model.therapyType.color
                )
                
                ParagraphText(SleepVitalMetric.HeartRateVariability,
                              percentChange: calculatePercentChange(baseline: model.baselineRestingHRV,
                                                                    exercise: model.exerciseRestingHRV) ?? 0,
                              therapyTypeDisplayName: model.therapyType.displayName(managedObjectContext))
                .padding(.leading)
                
            case .RespiratoryRate:
                BarGraphView(
                    title: "Sleeping Respiratory Rate",
                    baselineValue: model.baselineRespiratoryRate.isFinite ? model.baselineRespiratoryRate : 0,
                    exerciseValue: model.exerciseRespiratoryRate.isFinite ? model.exerciseRespiratoryRate : 0,
                    baselineLabel: "\(model.baselineRespiratoryRate.isFinite ? Int(model.baselineRespiratoryRate) : 0) br/min",
                    exerciseLabel: "\(model.exerciseRespiratoryRate.isFinite ? Int(model.exerciseRespiratoryRate) : 0) br/min",
                    barColor: model.therapyType.color
                )
                
                ParagraphText(SleepVitalMetric.RespiratoryRate,
                              percentChange: calculatePercentChange(baseline: model.baselineRespiratoryRate,
                                                                    exercise: model.exerciseRespiratoryRate) ?? 0,
                              therapyTypeDisplayName: model.therapyType.displayName(managedObjectContext))
                .padding(.leading)
                
            case .SP02:
                BarGraphView(
                    title: "Sleeping SPO2",
                    baselineValue: model.baselineSPO2.isFinite ? model.baselineSPO2 * 100 : 0,
                    exerciseValue: model.exerciseSPO2.isFinite ? model.exerciseSPO2 * 100 : 0,
                    baselineLabel: "\(model.baselineSPO2.isFinite ? Int(model.baselineSPO2 * 100) : 0)%",
                    exerciseLabel: "\(model.exerciseSPO2.isFinite ? Int(model.exerciseSPO2 * 100) : 0)%",
                    barColor: model.therapyType.color
                )
                
                ParagraphText(SleepVitalMetric.SP02,
                              percentChange: calculatePercentChange(baseline: model.baselineSPO2,
                                                                    exercise: model.exerciseSPO2) ?? 0,
                              therapyTypeDisplayName: model.therapyType.displayName(managedObjectContext))
                .padding(.leading)
            }
        }
    }
    
    private func calculatePercentChange(baseline: Double, exercise: Double) -> CGFloat? {
        if baseline != 0 {
            var percentage = CGFloat((exercise - baseline) / baseline * 100)
            
            return percentage.isFinite ? percentage : 0.0
        }
        return nil
    }
    
    
    @ViewBuilder
    private func ParagraphText(_ metricType: SleepVitalMetric, percentChange: CGFloat, therapyTypeDisplayName: String) -> some View {
        let indicator = changeIndicator(for: percentChange, metricType: metricType)
        let percentChangeText = String(format: "%.1f", abs(percentChange))
        let changeDescription = percentChange >= 0 ? "increase" : "decrease"
        
        HStack(spacing: 2) {
            Text(indicator.symbol)
                .font(.system(size: 14))
                .foregroundColor(indicator.color)
            
            Text(" You saw a ")
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            + Text(" \(percentChangeText)% ")
                .font(.system(size: 14))
                .foregroundColor(indicator.color)
                .fontWeight(.bold)
            
            + Text("\(changeDescription) ")
                .font(.system(size: 14))
                .foregroundColor(indicator.color)
                .fontWeight(.bold)
            
            + Text("on ")
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            + Text("\(therapyTypeDisplayName) days")
                .font(.system(size: 14))
                .foregroundColor(model.therapyType.color)
        }
        .padding(.bottom, 6)
    }
    
    private func changeIndicator(for percentChange: CGFloat, metricType: SleepVitalMetric) -> (symbol: String, color: Color) {
        // Define whether an increase in the metric is considered positive
        let isIncreasePositive: Bool
        switch metricType {
        case .HeartRateVariability, .SP02: // For HRV and SPO2, an increase is positive
            isIncreasePositive = true
        case .RestingHeartRate, .RespiratoryRate: // For RHR and Respiratory Rate, a decrease is positive
            isIncreasePositive = false
        default:
            isIncreasePositive = true
        }
        
        let isChangePositive = (percentChange > 0 && isIncreasePositive) || (percentChange < 0 && !isIncreasePositive)
        let color: Color = isChangePositive ? .green : .red
        let symbol: String = percentChange >= 0 ? "↑" : "↓"
        
        return (symbol, color)
    }
}

struct BarGraphView: View {
    var title: String
    var baselineValue: Double
    var exerciseValue: Double
    var baselineLabel: String
    var exerciseLabel: String
    var barColor: Color
    
    private let maxBarWidth: CGFloat = 200
    private let maxValue: Double = 100
    
    @State private var baselineBarWidth: CGFloat = 0
    @State private var exerciseBarWidth: CGFloat = 0
    
    private func calculateBarWidth(value: Double) -> CGFloat {
        if value == 0 || !value.isFinite {
            return 150
        } else {
            return CGFloat(value / maxValue) * maxBarWidth
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer()
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.bottom)
            
            // Baseline Bar with Label
            BarView2(label: baselineLabel, color: Color(white: 0.6), width: $baselineBarWidth)
            
            // Exercise Bar with Label
            BarView2(label: exerciseLabel, color: barColor, width: $exerciseBarWidth)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 10)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                baselineBarWidth = calculateBarWidth(value: baselineValue)
                exerciseBarWidth = calculateBarWidth(value: exerciseValue)
            }
        }
    }
}

struct BarView2: View {
    var label: String
    var color: Color
    @Binding var width: CGFloat
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [color.opacity(0.8), color]), startPoint: .leading, endPoint: .trailing))
                .frame(width: width, height: 35)
                .cornerRadius(6.0)
                .animation(.linear(duration: 2.0), value: width)
            
            Text(label)
                .font(.footnote)
                .foregroundColor(.white)
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

struct CustomMetricsPicker: View {
    @Binding var selectedMetric: SleepVitalMetric
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(SleepVitalMetric.allCases, id: \.self) { metric in
                MetricPickerItem(metric: metric, isSelected: selectedMetric == metric)
                    .onTapGesture {
                        self.selectedMetric = metric
                    }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color.black)
            .shadow(color: Color.gray.opacity(0.5), radius: 10, x: 0, y: 5))
    }
}


struct MetricPickerItem: View {
    let metric: SleepVitalMetric
    let isSelected: Bool
    
    var body: some View {
        Text(metric.displayTitle)
            .font(.system(size: 12, weight: .regular, design: .default))
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundColor(isSelected ? Color.orange : Color.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(isSelected ? Color.orange.opacity(0.2) : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
    }
}
