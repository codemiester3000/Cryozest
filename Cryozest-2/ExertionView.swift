import SwiftUI
import HealthKit

// MARK: - Exertion Widget (Collapsed State)

struct ExertionWidget: View {
    @ObservedObject var exertionModel: ExertionModel
    @ObservedObject var recoveryModel: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    @State private var animate = true

    private var isExpanded: Bool {
        expandedMetric == .exertion
    }

    private var exertionScore: Double {
        exertionModel.exertionScore
    }

    private var targetExertionUpperBound: Double {
        let recoveryScore = recoveryModel.recoveryScores.last ?? 0

        if recoveryScore == 0 {
            return 6.0 // Default target when no data
        }

        switch recoveryScore {
        case 90...100: return 10.0
        case 80..<90: return 9.0
        case 70..<80: return 8.0
        case 60..<70: return 7.0
        case 50..<60: return 6.0
        case 40..<50: return 5.0
        case 30..<40: return 4.0
        case 20..<30: return 3.0
        case 10..<20: return 2.0
        case 0..<10: return 1.0
        default: return 6.0
        }
    }

    private var targetExertionZone: String {
        let lowerBound = max(0, targetExertionUpperBound - 1.0)
        return String(format: "%.1f-%.1f", lowerBound, targetExertionUpperBound)
    }

    private var progress: Double {
        min(exertionScore / targetExertionUpperBound, 1.0)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else if progress >= 0.5 {
            return .yellow
        } else {
            return .green
        }
    }

    private var statusText: String {
        if exertionScore == 0 {
            return "No activity yet"
        } else if progress >= 1.0 {
            return "High load"
        } else if progress >= 0.8 {
            return "Near target"
        } else if progress >= 0.5 {
            return "On track"
        } else {
            return "Light day"
        }
    }

    private var recoveryScore: Int {
        Int(recoveryModel.recoveryScores.last ?? 0)
    }

    private var actionableMessage: String {
        if exertionScore == 0 {
            return "Start moving to build your training load"
        } else if progress >= 1.2 {
            return "High intensity - prioritize recovery tomorrow"
        } else if progress >= 1.0 {
            return "Target met - avoid overtraining"
        } else if progress >= 0.8 {
            return "Almost there - stay consistent"
        } else if progress >= 0.5 {
            return "Good pace - room for more intensity"
        } else {
            return "Light day - consider adding activity"
        }
    }

    private func formatTime(timeInMinutes: Double) -> String {
        let totalSeconds = Int(timeInMinutes * 60)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        if isExpanded {
            inlineExpandedView
        } else {
            collapsedView
        }
    }

    private var collapsedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and recovery context
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    // Animated flame icon
                    ZStack {
                        // Pulse effect
                        if progress >= 0.8 {
                            Circle()
                                .stroke(progressColor.opacity(0.3), lineWidth: 2)
                                .frame(width: 40, height: 40)
                                .scaleEffect(animate ? 1.0 : 1.2)
                                .opacity(animate ? 0.8 : 0.0)
                        }

                        Circle()
                            .fill(progressColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(progressColor)
                    }

                    // Main metric display
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Training Load")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", exertionScore))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text("of \(String(format: "%.1f", targetExertionUpperBound))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    // Status badge
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(statusText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(progressColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(progressColor.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(progressColor.opacity(0.3), lineWidth: 1)
                                    )
                            )

                        Text("\(Int(progress * 100))% of target")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // Recovery-based recommendation
                if recoveryScore > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.cyan.opacity(0.8))

                        Text("Recovery: \(Int(recoveryScore))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        Text("•")
                            .foregroundColor(.white.opacity(0.3))

                        Text("Target: \(targetExertionZone)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.leading, 52)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    progressColor,
                                    progressColor.opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 12)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 12)

            // Heart rate zones breakdown
            VStack(spacing: 8) {
                let zoneColors: [Color] = [.blue, .cyan, .green, .orange, .pink]
                let maxTime = exertionModel.zoneTimes.max() ?? 1

                ForEach(0..<5, id: \.self) { index in
                    let timeInMinutes = index < exertionModel.zoneTimes.count ? exertionModel.zoneTimes[index] : 0
                    let range = index < exertionModel.heartRateZoneRanges.count ? exertionModel.heartRateZoneRanges[index] : (lowerBound: 0.0, upperBound: 0.0)

                    HStack(spacing: 10) {
                        // Zone indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(zoneColors[index])
                                .frame(width: 8, height: 8)

                            Text("Zone \(index + 1)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 50, alignment: .leading)
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 6)

                                let fillWidth: CGFloat = timeInMinutes > 0 ?
                                    CGFloat(timeInMinutes / maxTime) * geometry.size.width : 0

                                if fillWidth > 0 {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(zoneColors[index])
                                        .frame(width: max(fillWidth, 6), height: 6)
                                }
                            }
                        }
                        .frame(height: 6)

                        // Time
                        Text(formatTime(timeInMinutes: timeInMinutes))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 40, alignment: .trailing)

                        // Heart rate range
                        Text("\(Int(range.lowerBound))-\(Int(range.upperBound))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(
            // Decorative flame pattern
            ZStack {
                GeometryReader { geo in
                    ForEach(0..<2, id: \.self) { index in
                        Image(systemName: "flame")
                            .font(.system(size: 50, weight: .ultraLight))
                            .foregroundColor(progressColor.opacity(0.04))
                            .rotationEffect(.degrees(-15))
                            .offset(
                                x: CGFloat(index) * (geo.size.width / 2) + 30,
                                y: 30
                            )
                    }
                }
            }
        )
        .modernWidgetCard(style: .hero)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                expandedMetric = .exertion
            }
        }
        .matchedGeometryEffect(id: "exertion-widget", in: namespace)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animate = false
            }
        }
    }

    private var inlineExpandedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(progressColor.opacity(0.2))
                                .frame(width: 36, height: 36)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(progressColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Training Load")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text(String(format: "%.1f", exertionScore))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text("of \(String(format: "%.1f", targetExertionUpperBound))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    Spacer()
                }

                // Expanded content
                VStack(alignment: .leading, spacing: 20) {
                    // Activity categories - expanded
                    VStack(spacing: 12) {
                        Text("Activity Breakdown")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.5)

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

                    // Heart rate zones
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Heart Rate Zones")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.5)

                        let zoneColors: [Color] = [.blue, .cyan, .green, .orange, .pink]
                        let maxTime = exertionModel.zoneTimes.max() ?? 1

                        VStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { index in
                                let timeInMinutes = index < exertionModel.zoneTimes.count ? exertionModel.zoneTimes[index] : 0
                                let range = index < exertionModel.heartRateZoneRanges.count ? exertionModel.heartRateZoneRanges[index] : (lowerBound: 0.0, upperBound: 0.0)

                                HeroZoneRow(
                                    zoneNumber: index + 1,
                                    timeInMinutes: timeInMinutes,
                                    heartRateRange: "\(Int(range.lowerBound))-\(Int(range.upperBound)) BPM",
                                    color: zoneColors[index],
                                    maxTime: maxTime
                                )
                            }
                        }
                    }

                    // Info card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.cyan.opacity(0.8))

                            Text("What is Training Load?")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your training load measures how hard you're pushing your cardiovascular system today. It's calculated from time spent in different heart rate zones.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Your recommended target adapts to your recovery score—when recovery is high, you can handle more load. Stay within your target to avoid overtraining.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(16)
        }
        .modernWidgetCard(style: .hero)
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                expandedMetric = nil
            }
        }
    }
}

// MARK: - Exertion Widget (Expanded State)

struct ExpandedExertionWidget: View {
    @ObservedObject var exertionModel: ExertionModel
    @ObservedObject var recoveryModel: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    private var exertionScore: Double {
        exertionModel.exertionScore
    }

    private var targetExertionUpperBound: Double {
        let recoveryScore = recoveryModel.recoveryScores.last ?? 0

        if recoveryScore == 0 {
            return 6.0
        }

        switch recoveryScore {
        case 90...100: return 10.0
        case 80..<90: return 9.0
        case 70..<80: return 8.0
        case 60..<70: return 7.0
        case 50..<60: return 6.0
        case 40..<50: return 5.0
        case 30..<40: return 4.0
        case 20..<30: return 3.0
        case 10..<20: return 2.0
        case 0..<10: return 1.0
        default: return 6.0
        }
    }

    private var progress: Double {
        min(exertionScore / targetExertionUpperBound, 1.0)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else if progress >= 0.5 {
            return .yellow
        } else {
            return .green
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(progressColor.opacity(0.2))
                                .frame(width: 36, height: 36)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(progressColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Training Load")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text(String(format: "%.1f", exertionScore))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text("of \(String(format: "%.1f", targetExertionUpperBound))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                            expandedMetric = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // Expanded content
                VStack(alignment: .leading, spacing: 20) {
                    // Activity categories - expanded
                    VStack(spacing: 12) {
                        Text("Activity Breakdown")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.5)

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

                    // Heart rate zones
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Heart Rate Zones")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.5)

                        let zoneColors: [Color] = [.blue, .cyan, .green, .orange, .pink]
                        let maxTime = exertionModel.zoneTimes.max() ?? 1

                        VStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { index in
                                let timeInMinutes = index < exertionModel.zoneTimes.count ? exertionModel.zoneTimes[index] : 0
                                let range = index < exertionModel.heartRateZoneRanges.count ? exertionModel.heartRateZoneRanges[index] : (lowerBound: 0.0, upperBound: 0.0)

                                HeroZoneRow(
                                    zoneNumber: index + 1,
                                    timeInMinutes: timeInMinutes,
                                    heartRateRange: "\(Int(range.lowerBound))-\(Int(range.upperBound)) BPM",
                                    color: zoneColors[index],
                                    maxTime: maxTime
                                )
                            }
                        }
                    }

                    // Info card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.cyan.opacity(0.8))

                            Text("What is Training Load?")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your training load measures how hard you're pushing your cardiovascular system today. It's calculated from time spent in different heart rate zones.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Your recommended target adapts to your recovery score—when recovery is high, you can handle more load. Stay within your target to avoid overtraining.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(16)
        }
        .modernWidgetCard(style: .hero)
        .matchedGeometryEffect(id: "exertion-widget", in: namespace)
    }
}

struct ActivityStatView: View {
    let label: String
    let minutes: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text("\(minutes) min")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HeroZoneRow: View {
    let zoneNumber: Int
    let timeInMinutes: Double
    let heartRateRange: String
    let color: Color
    let maxTime: Double

    private var timeString: String {
        let totalSeconds = Int(timeInMinutes * 60)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Zone indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text("Zone \(zoneNumber)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 55, alignment: .leading)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    let fillWidth: CGFloat = timeInMinutes > 0 ?
                        CGFloat(timeInMinutes / maxTime) * geometry.size.width : 0

                    if fillWidth > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: max(fillWidth, 6), height: 6)
                    }
                }
            }
            .frame(height: 6)

            // Time
            Text(timeString)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 45, alignment: .trailing)

            // Heart rate range
            Text(heartRateRange)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 75, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Original Exertion Views

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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(minutes)) min")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)

                    Text(zoneRange)
                        .font(.system(size: 10, weight: .medium))
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
                    .font(.system(size: 13, weight: .semibold))
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
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 50, alignment: .trailing)

            // Heart rate range
            Text(zoneRange)
                .font(.system(size: 11, weight: .medium))
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
                                    .font(.system(size: 24, weight: .bold))
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
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                Text(targetExertionZone)
                                    .font(.system(size: 18, weight: .bold))
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
                        .font(.system(size: 15, weight: .medium))
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
                            .font(.system(size: 16, weight: .semibold))
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
                            .font(.system(size: 12, weight: .medium))
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
