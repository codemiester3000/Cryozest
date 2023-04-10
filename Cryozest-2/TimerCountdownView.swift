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
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Time Remaining")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                    
                    Text(formatDuration(remainingTime))
                        .font(.system(size: 48, design: .monospaced))
                        .padding()

                    VStack {
                        HStack {
                            Button(action: {
                                cancelTimer()
                            }) {
                                Text("Cancel")
                                    .font(.title2)
                                    .bold()
                                    .frame(width: 100, height: 50)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                pauseOrResumeTimer()
                            }) {
                                Text(timer == nil ? "Resume" : "Pause")
                                    .font(.title2)
                                    .bold()
                                    .frame(width: 100, height: 50)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }

                        // Finish now button centered underneath the Cancel and Pause/Resume buttons
                        Button(action: {
                            remainingTime = 0
                        }) {
                            Text("Finish now")
                                .font(.title2)
                                .bold()
                                .frame(width: 125, height: 50)
                                .background(Color(red: 168/255, green: 191/255, blue: 135/255))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 12)
                    }
                    
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
