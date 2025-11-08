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
    var description: String
    var zoneRange: String
    var minutes: Double
    var color: Color
    var fullScaleTime: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(minutes)) min")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(color)

                    Text(zoneRange)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(geometry.size.width * CGFloat(minutes / fullScaleTime), geometry.size.width), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
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
        HStack(spacing: 12) {
            // Zone label with icon
            HStack(spacing: 6) {
                Circle()
                    .fill(zoneInfo.color)
                    .frame(width: 8, height: 8)
                Text("Zone \(zoneInfo.zoneNumber)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .leading)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    let fillWidth: CGFloat = zoneInfo.timeInMinutes > 0 ?
                        CGFloat(zoneInfo.timeInMinutes / maxTime) * geometry.size.width : 0

                    if fillWidth > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(zoneInfo.color)
                            .frame(width: max(fillWidth, 6), height: 6)
                    }
                }
            }
            .frame(height: 6)

            // Time spent
            Text(zoneInfo.timeSpent)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 50, alignment: .trailing)

            // Heart rate range
            Text(zoneRange)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
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
        ScrollView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.25),
                        Color(red: 0.1, green: 0.2, blue: 0.35),
                        Color(red: 0.15, green: 0.25, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header with ring
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text("Daily Exertion")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Button(action: {
                                    isPopoverVisible.toggle()
                                }) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                                .popover(isPresented: $isPopoverVisible) {
                                    ExertionInfoPopoverView()
                                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Target")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                Text(targetExertionZone)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                        }

                        Spacer()

                        ExertionRingView(exertionScore: exertionModel.exertionScore, targetExertionUpperBound: calculatedUpperBound)
                            .frame(width: 100, height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // User statement card
                    let userStatement = recoveryModel.generateUserStatement()
                    Text(userStatement)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.12),
                                            Color.white.opacity(0.06)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)

                    // Exertion categories
                    VStack(spacing: 10) {
                        ExertionBarView(
                            label: "Light Activity",
                            description: "Easy pace, conversational",
                            zoneRange: "Zone 1",
                            minutes: exertionModel.recoveryMinutes,
                            color: .teal,
                            fullScaleTime: 30.0
                        )
                        ExertionBarView(
                            label: "Moderate Activity",
                            description: "Building fitness, steady effort",
                            zoneRange: "Zones 2-3",
                            minutes: exertionModel.conditioningMinutes,
                            color: .green,
                            fullScaleTime: 45.0
                        )
                        ExertionBarView(
                            label: "Vigorous Activity",
                            description: "High effort, pushing limits",
                            zoneRange: "Zones 4-5",
                            minutes: exertionModel.overloadMinutes,
                            color: .red,
                            fullScaleTime: 20.0
                        )
                    }
                    .padding(.horizontal, 20)

                    // Heart rate zones section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Heart Rate Zones")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)

                        let maxTime = exertionModel.zoneTimes.max() ?? 1

                        VStack(spacing: 1) {
                            ForEach(Array(zip(zoneInfos.indices, zoneInfos)), id: \.1.zoneNumber) { index, zoneInfo in
                                if index < exertionModel.heartRateZoneRanges.count {
                                    let range = exertionModel.heartRateZoneRanges[index]
                                    let rangeString = "\(Int(range.lowerBound))-\(Int(range.upperBound)) BPM"
                                    ZoneItemView(zoneInfo: zoneInfo, zoneRange: rangeString, maxTime: maxTime)
                                } else {
                                    ZoneItemView(zoneInfo: zoneInfo, zoneRange: "N/A", maxTime: maxTime)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                        )
                        .padding(.horizontal, 20)

                        Text("Estimated time in each zone")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
