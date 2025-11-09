import SwiftUI

struct DeviceSafetyWarningView: View {
    @Binding var isPresented: Bool
    let therapyType: TherapyType
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            // Modern gradient background matching app theme
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

            VStack(spacing: 24) {
                Spacer()

                // Warning icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 8)

                // Title
                Text("Device Safety Warning")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Warning message
                VStack(spacing: 16) {
                    Text(warningMessage)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)

                    // Temperature info box
                    VStack(spacing: 8) {
                        Text("iPhone Operating Range")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)

                        Text("0° to 35° C (32° to 95° F)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 32)
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onContinue()
                        isPresented = false
                    }) {
                        HStack(spacing: 12) {
                            Text("I Understand")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, Color.white.opacity(0.95)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 10)
                    }

                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }

    private var warningMessage: String {
        return "Please ensure your device is in a safe location during your wellness session."
    }

    private var shouldShowWarning: Bool {
        // COMMENTED OUT FOR APP STORE COMPLIANCE
        // switch therapyType {
        // case .drySauna, .hotYoga, .coldPlunge, .coldShower, .iceBath:
        //     return true
        // default:
        //     return false
        // }
        return false
    }
}
