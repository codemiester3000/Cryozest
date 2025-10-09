import SwiftUI

struct TimerCountdownView: View {
    @Binding var timerDuration: TimeInterval
    @Binding var showTimerCountdownView: Bool
    @Binding var showSessionSummary: Bool
    
    @State private var remainingTime: TimeInterval
    @State private var timer: Timer?
    
    init(timerDuration: Binding<TimeInterval>, showTimerCountdownView: Binding<Bool>, showSessionSummary: Binding<Bool>) {
        _timerDuration = timerDuration
        _showTimerCountdownView = showTimerCountdownView
        _remainingTime = State(initialValue: timerDuration.wrappedValue)
        _showSessionSummary = showSessionSummary
    }
    
    var body: some View {
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

                // Subtle gradient overlay
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Time remaining title
                    Text("Time Remaining")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)

                    // Timer display with modern circle
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 12)
                            .frame(width: 280, height: 280)

                        Circle()
                            .trim(from: 0, to: CGFloat(remainingTime / timerDuration))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: remainingTime)

                        VStack(spacing: 8) {
                            Text(formatDuration(remainingTime))
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("\(Int((remainingTime / timerDuration) * 100))%")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    Spacer()

                    // Control buttons
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Button(action: {
                                cancelTimer()
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.red.opacity(0.2))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                            }

                            Button(action: {
                                pauseOrResumeTimer()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: timer == nil ? "play.fill" : "pause.fill")
                                        .font(.system(size: 16))
                                    Text(timer == nil ? "Resume" : "Pause")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.cyan.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                        }

                        Button(action: {
                            remainingTime = 0
                        }) {
                            HStack(spacing: 8) {
                                Text("Finish Now")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, Color.white.opacity(0.95)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: .white.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                remainingTime = timerDuration
                startTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                timer?.invalidate()
                showSessionSummary = true
                showTimerCountdownView = false
            }
        }
    }
    
    func pauseOrResumeTimer() {
        if timer == nil {
            startTimer()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
        showSessionSummary = false
        showTimerCountdownView = false
    }
}
