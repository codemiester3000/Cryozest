import SwiftUI
import HealthKit

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
    var fullScaleTime: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Rectangle()
                    .opacity(0.3)
                    .foregroundColor(color)
                    .cornerRadius(9)
                GeometryReader { geometry in
                    Rectangle()
                        .frame(width: min(geometry.size.width * CGFloat(minutes / fullScaleTime), geometry.size.width))
                        .foregroundColor(color)
                        .cornerRadius(9)
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
                .padding(.horizontal, 22)
            }
            .padding(.horizontal, 16)
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
    var zoneRange: String
    var maxTime: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Text("Zone \(zoneInfo.zoneNumber)")
                .foregroundColor(zoneInfo.color)
                .padding(.leading, 5)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    let fillWidth: CGFloat = zoneInfo.timeInMinutes > 0 ?
                    CGFloat(zoneInfo.timeInMinutes / maxTime) * geometry.size.width * 0.6 : 5
                    
                    if fillWidth > 5 {
                        Rectangle()
                            .frame(width: fillWidth, height: 5)
                            .foregroundColor(zoneInfo.color)
                            .cornerRadius(2.5)
                        
                        Text(zoneInfo.timeSpent)
                            .foregroundColor(.white)
                            .position(x: fillWidth + 30, y: geometry.size.height / 2)
                    } else {
                        // If no time or very short time, only show the circle
                        Circle()
                            .fill(zoneInfo.color)
                            .frame(width: 5, height: 5)
                            .position(x: 0, y: geometry.size.height / 2)
                    }
                }
            }
            .frame(height: 5)
            
            Spacer()
            
            Text(zoneRange)
                .foregroundColor(.gray)
                .padding(.trailing, 5)
        }
        .padding(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
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
    
    var exertionScore: Double {
        return exertionModel.exertionScore
    }
    
    
    var zoneInfos: [ZoneInfo] {
        if exertionModel.zoneTimes.isEmpty {
            return (1...5).map { index in
                let colors: [Color] = [.blue, .cyan, .green, .orange, .pink]
                return ZoneInfo(
                    zoneNumber: index,
                    timeSpent: formatTime(timeInMinutes: 0),
                    color: colors[(index - 1) % colors.count],
                    timeInMinutes: 0
                )
            }
        } else {
            return exertionModel.zoneTimes.enumerated().map { (index, timeInMinutes) in
                let colors: [Color] = [.blue, .cyan, .green, .orange, .pink]
                let timeSpentString = formatTime(timeInMinutes: timeInMinutes)
                return ZoneInfo(
                    zoneNumber: index + 1,
                    timeSpent: timeSpentString,
                    color: colors[index % colors.count],
                    timeInMinutes: timeInMinutes
                )
            }
        }
    }
    
    
    // Computed property for target exertion zone
    var targetExertionZone: String {
        let recoveryScore = recoveryModel.recoveryScores.last ?? 0
        
        if recoveryScore == 0 {
            return "5.0-6.0" // Default exertion target when no data
        }
        
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
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Set the background to black and ignore safe area
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack() {
                            Text("Daily Exertion")
                                .font(.system(size: 20)) // Adjust the font size here
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
                        
                        VStack(alignment: .leading) {
                                Text("Today's Exertion Target:")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                
                                Text("\(targetExertionZone)")
                                    .font(.system(size: 17))
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.vertical)
                        .padding(.horizontal, 22)
                        
                        Spacer()
                          
                          Spacer()
                    
                    ExertionRingView(exertionScore: exertionModel.exertionScore, targetExertionUpperBound: calculatedUpperBound)
                        .frame(width: 120, height: 120)
                        .padding(.horizontal, 22)
                }
                
                Spacer(minLength: 10)

                VStack() {
                    // TODO: (Owen) This seems like a bug. why is the exertionView
                    // pulling this value off the recovery model?
                    let userStatement = recoveryModel.generateUserStatement()
                    Text(userStatement)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 1)
                
                let maxTime = exertionModel.zoneTimes.max() ?? 1
                
                Spacer(minLength: 10)
                
                VStack(alignment: .leading) {
                    ExertionBarView(label: "RECOVERY", minutes: exertionModel.recoveryMinutes, color: .teal, fullScaleTime: 30.0)
                    ExertionBarView(label: "CONDITIONING", minutes: exertionModel.conditioningMinutes, color: .green, fullScaleTime: 45.0)
                    ExertionBarView(label: "HIGH INTENSITY", minutes: exertionModel.overloadMinutes, color: .red, fullScaleTime: 20.0)
                }
                .padding(.top, 10)
                .padding(.horizontal, 6)
                .padding(.bottom, 20)
                
                ForEach(Array(zip(zoneInfos.indices, zoneInfos)), id: \.1.zoneNumber) { index, zoneInfo in
                    VStack(spacing: 0.1) {
                        HStack {
                            if index < exertionModel.heartRateZoneRanges.count {
                                let range = exertionModel.heartRateZoneRanges[index]
                                let rangeString = "\(Int(range.lowerBound))-\(Int(range.upperBound))BPM"
                                ZoneItemView(zoneInfo: zoneInfo, zoneRange: rangeString, maxTime: maxTime)
                                    .background(Color.black) // Set the background of ZoneItemView to black
                            } else {
                                ZoneItemView(zoneInfo: zoneInfo, zoneRange: "N/A", maxTime: maxTime)
                                    .background(Color.black) // Set the background of ZoneItemView to black
                            }
                        }
                        .padding(.horizontal, 19)
                        .frame(maxWidth: .infinity)
                        
                        if index < zoneInfos.count - 1 {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 6.0)
                        }
                    }
                    .background(Color.black)
                }
                
                HStack {
                    Text("Estimated time in each heart rate zone")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.leading, 24)
                    Spacer()
                }
                .padding(.top)
                .padding(.bottom, 30)
            }
        }
    }
}
