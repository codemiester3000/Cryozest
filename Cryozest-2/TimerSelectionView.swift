import SwiftUI

struct TimerSelectionView: View {
    @State private var timerDuration: TimeInterval
    @State private var showTimerCountdownView: Bool = false
    @State private var showCustomDurationPicker: Bool = false
    @State private var showSessionSummary: Bool = false
    // Updated for App Store compliance
    @State private var therapyType: TherapyType = .running
    @State private var showSafetyWarning: Bool = false
    @State private var pendingTimerStart: Bool = false

    init(timerDuration: TimeInterval = 0) {
        _timerDuration = State(initialValue: timerDuration)
    }
    
    let defaultDurations: [TimeInterval] = [300, 600, 900, 1800, 2700]
    
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

            VStack {
                Text("Select Timer")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top, 16)
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
                            if requiresSafetyWarning(therapyType) {
                                showSafetyWarning = true
                                pendingTimerStart = true
                            } else {
                                showTimerCountdownView = true
                            }
                        }) {
                            circleContent(duration: duration)
                        }
                    }
                    
                    Button(action: {
                        showCustomDurationPicker = true
                    }) {
                        circleContent(custom: true)
                    }
                }
                .padding()
                }
            }
        }
        .sheet(isPresented: $showCustomDurationPicker) {
            CustomDurationPickerView(customDuration: $timerDuration, showTimerCountdownView: $showTimerCountdownView)
        }
        .sheet(isPresented: $showTimerCountdownView) {
            TimerCountdownView(timerDuration: $timerDuration, showTimerCountdownView: $showTimerCountdownView, showSessionSummary: $showSessionSummary)
        }
        .sheet(isPresented: $showSessionSummary) {
            SessionSummary(duration: timerDuration, temperature: nil ?? 0, therapyType: $therapyType, bodyWeight: nil ?? 0)
        }
        .fullScreenCover(isPresented: $showSafetyWarning) {
            DeviceSafetyWarningView(
                isPresented: $showSafetyWarning,
                therapyType: therapyType,
                onContinue: {
                    if pendingTimerStart {
                        showTimerCountdownView = true
                        pendingTimerStart = false
                    }
                }
            )
        }
    }

    func requiresSafetyWarning(_ type: TherapyType) -> Bool {
        // Safety warnings disabled for App Store compliance
        return false
    }
    
    // Modern circle button styling
    func circleContent(duration: TimeInterval? = nil, custom: Bool = false) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Circle()
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 3)
                )
                .shadow(color: Color.cyan.opacity(0.3), radius: 15, x: 0, y: 8)

            if custom {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.plus")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.cyan)
                    Text("Custom")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                VStack(spacing: 4) {
                    Text(String(format: "%02d", Int(duration! / 60)))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)

                    Text("MINUTES")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.4, height: UIScreen.main.bounds.width * 0.4)
    }
}
