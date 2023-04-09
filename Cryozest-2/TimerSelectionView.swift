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
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.15))
                                
                                VStack {
                                    Text(String(format: "%02d", Int(duration / 60)))
                                        .font(.system(size: 40, design: .rounded))
                                        .bold()
                                        .foregroundColor(Color.orange)
                                    
                                    Text("MIN")
                                        .font(.system(size: 20, design: .rounded))
                                        .bold()
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: circleSize, height: circleSize)
                            
                        }
                    }
                    
                    Button(action: {
                        showCustomDurationPicker = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.15))
                            
                            Text("Custom")
                                .font(.system(size: 30, design: .rounded))
                                .bold()
                                .foregroundColor(.orange)
                        }
                        .frame(width: circleSize, height: circleSize)
                        
                    }
                }
                .padding()
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
}
