import SwiftUI

struct CustomDurationPickerView: View {
    @Binding var customDuration: TimeInterval
    @Binding var showTimerCountdownView: Bool
    @Environment(\.presentationMode) var presentationMode

    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

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

            NavigationView {
                VStack(spacing: 24) {
                    Text("Custom Duration")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                
                    HStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Minutes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            Picker("", selection: $minutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)").tag(minute)
                                        .foregroundColor(.white)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                        }

                        VStack(spacing: 8) {
                            Text("Seconds")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            Picker("", selection: $seconds) {
                                ForEach(0..<60) { second in
                                    Text("\(second)").tag(second)
                                        .foregroundColor(.white)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    Button(action: {
                        customDuration = TimeInterval(minutes * 60 + seconds)
                        presentationMode.wrappedValue.dismiss()
                        showTimerCountdownView = true
                    }) {
                        HStack(spacing: 8) {
                            Text("Set Timer")
                                .font(.system(size: 18, weight: .semibold))
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
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
                .navigationBarTitle("Custom Timer", displayMode: .inline)
            }
        }
    }
}
