import SwiftUI

struct WelcomeView: View {
    @State private var showNext = false
    @State private var animateContent = false
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var managedObjectContext

    var body: some View {
        ZStack {
            // Deep navy background
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo section with animation
                VStack(spacing: 24) {
                    Image("TestLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140)
                        .shadow(color: .white.opacity(0.2), radius: 20, x: 0, y: 10)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0)

                    VStack(spacing: 12) {
                        Text("Welcome to")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(animateContent ? 1.0 : 0)

                        Text("Cryozest")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(animateContent ? 1.0 : 0)

                        Text("Your wellness journey starts here")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                            .opacity(animateContent ? 1.0 : 0)
                    }
                }
                .padding(.bottom, 60)

                // Feature cards
                VStack(spacing: 20) {
                    FeatureCard(
                        icon: "waveform.path.ecg.rectangle.fill",
                        title: "Track Your Progress",
                        description: "Monitor health metrics and watch your wellness evolve",
                        accentColor: .cyan
                    )
                    .opacity(animateContent ? 1.0 : 0)
                    .offset(y: animateContent ? 0 : 20)

                    FeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Build Healthy Habits",
                        description: "Develop lasting routines with data-driven insights",
                        accentColor: .green
                    )
                    .opacity(animateContent ? 1.0 : 0)
                    .offset(y: animateContent ? 0 : 20)

                    FeatureCard(
                        icon: "lock.shield.fill",
                        title: "Privacy First",
                        description: "Your data stays on your device, always",
                        accentColor: .orange
                    )
                    .opacity(animateContent ? 1.0 : 0)
                    .offset(y: animateContent ? 0 : 20)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Get Started button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        showNext = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
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
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .opacity(animateContent ? 1.0 : 0)
                .offset(y: animateContent ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateContent = true
            }
        }
        .fullScreenCover(isPresented: $showNext) {
            TherapyTypeSelectionView()
                .environment(\.managedObjectContext, managedObjectContext)
                .environmentObject(appState)
                .onAppear {
                    // Mark as launched when they continue from welcome
                    appState.hasLaunchedBefore = true
                }
        }
    }
}

// Feature card component
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(accentColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}
