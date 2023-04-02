import SwiftUI

struct TimerSelectionView: View {
    @Binding var timerDuration: TimeInterval
    @State private var showTimerCountdownView: Bool = false
    @State private var showCustomDurationPicker: Bool = false
    
    let defaultDurations: [TimeInterval] = [60, 300, 600, 900, 1800, 2700, 3600]
    
    var body: some View {
        VStack {
            Text("Select Timer")
                .font(.largeTitle)
                .bold()
                .padding()
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.fixed(100), spacing: 40),
                    GridItem(.fixed(100), spacing: 40)
                ], spacing: 40) {
                    ForEach(defaultDurations, id: \.self) { duration in
                        Button(action: {
                            timerDuration = duration
                            showTimerCountdownView = true
                        }) {
                            Text(formatDuration(duration))
                                .font(.title2)
                                .bold()
                                .frame(width: 100, height: 100)
                        }
                        .background(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 125, height: 125)
                        )
                        .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showCustomDurationPicker = true
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.title2)
                            Text("Custom")
                                .font(.title2)
                                .bold()
                        }
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 125, height: 125)
                        )
                        .foregroundColor(.blue)
                    }
                }
                .padding()
            }
        }
        .background(Color.darkBackground.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showCustomDurationPicker) {
            CustomDurationPickerView(customDuration: $timerDuration)
        }
        .sheet(isPresented: $showTimerCountdownView) {
            TimerCountdownView(timerDuration: $timerDuration, showTimerCountdownView: $showTimerCountdownView)
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
