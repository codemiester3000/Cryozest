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
     
            VStack {
                Text("Time Remaining")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                Text(formatDuration(remainingTime))
                    .font(.system(size: 48, design: .monospaced))
                    .padding()
                
                HStack {
                    Button(action: {
                        pauseOrResumeTimer()
                    }) {
                        Text(timer == nil ? "Resume" : "Pause")
                            .font(.title2)
                            .bold()
                            .frame(width: 100, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
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
                }
                .padding()
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
