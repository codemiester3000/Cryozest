import SwiftUI
import HealthKit

class ExertionModel: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var exertionScore: Double = 0.0
    @Published var zoneTimes: [Double] = []
    @Published var recoveryMinutes: Double = 0
    @Published var conditioningMinutes: Double = 0
    @Published var overloadMinutes: Double = 0
    @Published var avgRestingHeartRate: Double = 0
    
    
    var maxExertionTime: Double {
        let maxTime = max(recoveryMinutes, conditioningMinutes, overloadMinutes)
        return maxTime == 0 ? 1 : maxTime
    }
    
    init() {
        fetchExertionScoreAndTimes()
    }
    
    func updateExertionCategories() {
        // This function will be called once the zoneTimes are updated
        if zoneTimes.count >= 3 {
            let recoveryTime = zoneTimes[0]
            let conditioningTime = zoneTimes[1] + zoneTimes[2]
            let overloadTime = zoneTimes.count > 3 ? zoneTimes.dropFirst(3).reduce(0, +) : 0
            
            DispatchQueue.main.async {
                self.recoveryMinutes = recoveryTime
                self.conditioningMinutes = conditioningTime
                self.overloadMinutes = overloadTime
            }
        }
    }
    
    func fetchExertionScoreAndTimes() {
        // Fetch the user's age
        HealthKitManager.shared.fetchUserAge { [weak self] (age: Int?, error: Error?) in
            guard let self = self else { return }
            let userAge = age ?? 30 // Use the fetched age or default to 30

            // Fetch the average resting heart rate
            HealthKitManager.shared.fetchAvgRestingHeartRate(numDays: 30) { [weak self] avgRestingHeartRate in
                guard let self = self, let avgRestingHeartRate = avgRestingHeartRate else {
                    print("Error fetching average resting heart rate")
                    return
                }

                self.avgRestingHeartRate = avgRestingHeartRate

                let startDate = Calendar.current.startOfDay(for: Date())
                let endDate = Date()

                // Fetch heart rate data
                HealthKitManager.shared.fetchHeartRateData(from: startDate, to: endDate) { (results, error) in
                    guard let results = results else {
                        print("Error fetching heart rate data: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }

                    // Calculate exertion score
                    DispatchQueue.global().async {
                        do {
                            let score = try self.calculateExertionScore(
                                userAge: userAge,
                                heartRateData: results,
                                avgRestingHeartRate: self.avgRestingHeartRate
                            )
                            DispatchQueue.main.async {
                                self.exertionScore = score
                                self.updateExertionCategories()
                            }
                        } catch {
                            print("Error calculating exertion score: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func calculateExertionScore(userAge: Int, heartRateData: [HKQuantitySample], avgRestingHeartRate: Double) throws -> Double {
        let zoneMultipliers: [Double] = [0.0668, 0.1198, 0.13175, 0.1581, 0.18975]
        let zoneUpperBoundaries: [Double] = [0.6, 0.7, 0.8, 0.9, 1.1]
        
        var exertionScore = 0.0
        DispatchQueue.main.async {
            self.zoneTimes = []
        }
        
        for (index, upperBoundary) in zoneUpperBoundaries.enumerated() {
            let lowerBoundary = index == 0 ? 0.5 : zoneUpperBoundaries[index - 1]
            let timeInZone = calculateTimeInZone(
                       for: heartRateData,
                       userAge: userAge,
                       lowerBoundMultiplier: lowerBoundary,
                       upperBoundMultiplier: upperBoundary,
                       avgRestingHeartRate: avgRestingHeartRate  // Passing the avgRestingHeartRate
                   )
                   exertionScore += timeInZone * zoneMultipliers[index]

                   DispatchQueue.main.async {
                       self.zoneTimes.append(timeInZone)
                   }
               }
        
        return exertionScore
    }
    
    private func calculateTimeInZone(for samples: [HKQuantitySample], userAge: Int, lowerBoundMultiplier: Double, upperBoundMultiplier: Double, avgRestingHeartRate: Double) -> Double {
        var zoneTime: TimeInterval = 0
        var previousSample: HKQuantitySample?
        
        let maxHeartRate = 207 - (0.7 * Double(userAge))
        let heartRateReserve = maxHeartRate - avgRestingHeartRate
        
        for sample in samples {
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            
            let lowerBoundHeartRate = (heartRateReserve * lowerBoundMultiplier) + avgRestingHeartRate
            let upperBoundHeartRate = (heartRateReserve * upperBoundMultiplier) + avgRestingHeartRate
            
            if heartRate >= lowerBoundHeartRate && heartRate < upperBoundHeartRate {
                if let previousSample = previousSample {
                    let timeDifference = sample.startDate.timeIntervalSince(previousSample.endDate)
                    zoneTime += timeDifference
                }
                previousSample = sample
            } else {
                previousSample = nil
            }
        }
        
        let minutesInZone = zoneTime / 60
        return minutesInZone
    }
    
    
    
    func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        return min(max(range.lowerBound, value), range.upperBound)
    }
}


struct ExertionRingView: View {
    var exertionScore: Double
    var targetExertionUpperBound: Double
    
    var body: some View {
        let progress = min(exertionScore / targetExertionUpperBound, 1.0)
        let percentage = Int(progress * 100)
        let exertionDisplay = String(format: "%.1f/%.1f", exertionScore, targetExertionUpperBound)
        let progressColor = Color(red: 1.0 - progress, green: progress, blue: 0)
        
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .foregroundColor(Color.gray.opacity(0.5))
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .foregroundColor(progressColor)
                .rotationEffect(.degrees(-90))
                .frame(width: 120, height: 120)
            
            VStack(spacing: 2) {
                Text("\(percentage)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text(exertionDisplay)
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.white)
            }
        }
    }
}

struct ExertionBarView: View {
    var label: String
    var minutes: Double
    var color: Color
    var fullScaleTime: Double  // Renamed parameter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Rectangle()
                    .opacity(0.3)
                    .foregroundColor(color)
                    .cornerRadius(0)
                GeometryReader { geometry in
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(minutes / fullScaleTime))
                        .foregroundColor(color)
                        .cornerRadius(0)
                }
                
                HStack {
                    Text(label)
                        .foregroundColor(.white)
                        .bold()
                    Spacer()
                    Text("\(Int(minutes)) min")
                        .foregroundColor(.white)
                        .bold()
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 50)
        }
    }
}

struct ZoneInfo {
    var zoneNumber: Int
    var timeSpent: String
    var color: Color
    var timeInMinutes: Double
}

struct ZoneItemView: View {
    var zoneInfo: ZoneInfo
    var maxTime: Double
    
    var body: some View {
        HStack {
            Circle()
                .fill(zoneInfo.color)
                .frame(width: 10, height: 10)
            Text("Zone \(zoneInfo.zoneNumber)")
                .foregroundColor(.white)
                .padding(.leading, 5)
            
            Spacer()
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 5)
                        .foregroundColor(Color.gray.opacity(0.3))
                        .cornerRadius(2.5)
                    
                    if zoneInfo.timeInMinutes > 0 {
                        Rectangle()
                            .frame(width: geometry.size.width * CGFloat(zoneInfo.timeInMinutes / maxTime), height: 5)
                            .foregroundColor(zoneInfo.color)
                            .cornerRadius(2.5)
                    }
                }
            }
            .frame(height: 5)
            
            Text(zoneInfo.timeSpent)
                .foregroundColor(.white)
                .padding(.leading, 5)
        }
        // Reduce the overall padding around each ZoneItemView
        .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
        .background(Color.black.opacity(0.8))
        .cornerRadius(5)
    }
}

struct ExertionInfoPopoverView: View {
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exertion serves as a valuable indicator of your daily cardiovascular fitness load over the course of the day. This rating, measured on a scale of 0-10, is derived from your heart rate zones, where specific zones (such as Zone 1, Zone 2, Zone 3) correspond to different workout intensities. Exertion scores increase with higher workout intensity levels. To determine your maximum heart rate, a simple calculation (220 minus your age) is used to define these heart rate zones.")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    Text("The concept of exertion revolves around the duration spent exercising above your heart rate reserve, with higher scores allocated to more intense efforts. Your recommended exertion target zone depends on your current state of recovery and is presented as a suggestion. Always maintain a vigilant awareness of how your body responds. It's often wiser to stay below the recommended exertion target to prevent overtraining and protect your recovery process. Stay connected to your body, adjusting your training regimen based on your sensations and overall well-being.")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .padding()
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
    }
}


struct ExertionView: View {
    @ObservedObject var exertionModel: ExertionModel
    @ObservedObject var recoveryModel: RecoveryGraphModel
    @State private var isPopoverVisible = false
    
    var body: some View {
        
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack() {
                        Text("Daily Exertion")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            isPopoverVisible.toggle()
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color.blue)
                        }
                        .padding(.leading, 8)
                        .popover(isPresented: $isPopoverVisible) {
                            ExertionInfoPopoverView()
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        }
                    }
                    
                    VStack {
                        Text("Today's Exertion Target:\n")
                            .font(.footnote)  // Set the font size for the initial part
                            .foregroundColor(.gray)
                        
                        +
                        Text("\(targetExertionZone)")
                            .font(.system(size: 17))
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }.padding(.vertical, 1)
                    
                    
                }
                .padding(.vertical)
                
                
                Spacer()
                
                ExertionRingView(exertionScore: exertionModel.exertionScore, targetExertionUpperBound: calculatedUpperBound)
                    .frame(width: 120, height: 120)
            }
            //.padding(.horizontal, 6)
            
            VStack() {
                let userStatement = recoveryModel.generateUserStatement()
                Text(userStatement)
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            
            VStack(alignment: .leading) {
                //                Text("Training Zones")
                //                    .font(.title2)
                //                    .fontWeight(.semibold)
                //                    .foregroundColor(.white)
                //                    .padding(.vertical)
                
                ExertionBarView(label: "RECOVERY", minutes: exertionModel.recoveryMinutes, color: .teal, fullScaleTime: 30.0)
                ExertionBarView(label: "CONDITIONING", minutes: exertionModel.conditioningMinutes, color: .green, fullScaleTime: 45.0)
                ExertionBarView(label: "OVERLOAD", minutes: exertionModel.overloadMinutes, color: .red, fullScaleTime: 20.0)
            }
            .padding(.top)
            
            // Dynamically create zoneInfos from model.zoneTimes
            let maxTime = exertionModel.zoneTimes.max() ?? 1
            let zoneInfos = exertionModel.zoneTimes.enumerated().map { (index, timeInMinutes) -> ZoneInfo in
                let colors: [Color] = [.blue, .cyan, .green, .orange, .pink]
                let timeSpentString = formatTime(timeInMinutes: timeInMinutes)
                
                return ZoneInfo(
                    zoneNumber: index + 1,
                    timeSpent: timeSpentString,
                    color: colors[index % colors.count],
                    timeInMinutes: timeInMinutes
                )
            }
            
            ForEach(zoneInfos, id: \.zoneNumber) { zoneInfo in
                ZoneItemView(zoneInfo: zoneInfo, maxTime: maxTime)
            }
        }
        .padding(.horizontal, 22)
    }
    
    // Computed property for target exertion zone
    var targetExertionZone: String {
        let recoveryScore = recoveryModel.recoveryScores.last ?? 0
        switch recoveryScore {
        case 90...100:
            return "9.0-10.0"
        case 80..<90:
            return "8.0-9.0"
        case 70..<80:
            return "7.0-8.0"
        case 60..<70:
            return "6.0-7.0"
        case 50..<60:
            return "5.0-6.0"
        case 40..<50:
            return "4.0-5.0"
        case 30..<40:
            return "3.0-4.0"
        case 20..<30:
            return "2.0-3.0"
        case 10..<20:
            return "1.0-2.0"
        case 0..<10:
            return "0.0-1.0"
        default:
            return "Not available"
        }
    }
    
    var calculatedUpperBound: Double {
        let bounds = targetExertionZone.split(separator: "-").compactMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        return bounds.last ?? 8.0 // ROB - if no exertion target it will automatically set it to 8
    }
    
    
    func formatTime(timeInMinutes: Double) -> String {
        let totalSeconds = Int(timeInMinutes * 60)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
