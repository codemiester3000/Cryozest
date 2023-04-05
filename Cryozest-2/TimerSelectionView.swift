import SwiftUI

struct TimerSelectionView: View {
    @State private var timerDuration: TimeInterval
    @State private var showTimerCountdownView: Bool = false
    @State private var showCustomDurationPicker: Bool = false
    @State private var showSessionSummary: Bool = false
    
    init(timerDuration: TimeInterval = 0) {
        _timerDuration = State(initialValue: timerDuration)
    }

    let defaultDurations: [TimeInterval] = [300, 600, 900, 1800, 2700]
    
    var body: some View {
        VStack {
            Text("Select Timer")
                .font(.largeTitle)
                .bold()
                .padding()
                .foregroundColor(.white)
            
            ScrollView {
                let circleSize = UIScreen.main.bounds.width * 0.4
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40)
                ], spacing: 40) {
                    ForEach(defaultDurations, id: \.self) { duration in
                        Button(action: {
                            timerDuration = duration
                            showTimerCountdownView = true
                        }) {
                            Text(formatDuration(duration))
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                                .frame(width: circleSize, height: circleSize)
                                .background(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 4)
                                )
                        }
                    }
                    
                    Button(action: {
                        showCustomDurationPicker = true
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("Custom")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                        }
                        .frame(width: circleSize, height: circleSize)
                        .background(
                            Circle()
                                .stroke(Color.blue, lineWidth: 4)
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color.darkBackground.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showCustomDurationPicker) {
            CustomDurationPickerView(customDuration: $timerDuration, showTimerCountdownView: $showTimerCountdownView)
        }
        .sheet(isPresented: $showTimerCountdownView) {
            TimerCountdownView(timerDuration: $timerDuration, showTimerCountdownView: $showTimerCountdownView, showSessionSummary: $showSessionSummary)
        }
        .sheet(isPresented: $showSessionSummary) {
            SessionSummary(duration: timerDuration, temperature: nil ?? 0, therapyType: TherapyType.drySauna, bodyWeight: nil ?? 0)
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

