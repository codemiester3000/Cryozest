import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    @State private var innerGlow: CGFloat = 0
    @State private var snowflakeRotation: Double = 0

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            // Subtle radial ambient light
            RadialGradient(
                colors: [Color.cyan.opacity(0.08), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 200
            )
            .scaleEffect(ringScale)
            .opacity(ringOpacity)

            ZStack {
                // Outer pulse ring — expands and fades
                Circle()
                    .stroke(Color.cyan.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 150, height: 150)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)

                // Static ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.5), Color.cyan.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 130, height: 130)
                    .opacity(ringOpacity)

                // Inner glow disc
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.cyan.opacity(0.25),
                                Color.cyan.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 65
                        )
                    )
                    .frame(width: 130, height: 130)
                    .opacity(innerGlow)

                // Snowflake
                Image(systemName: "snowflake")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .cyan.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .rotationEffect(.degrees(snowflakeRotation))
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
        .onAppear {
            // Icon springs in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Ring fades in slightly delayed
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }

            // Inner glow breathes up
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                innerGlow = 1.0
            }

            // Slow snowflake rotation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                snowflakeRotation = 360
            }

            // Continuous pulse ring
            withAnimation(
                .easeOut(duration: 2.0)
                .repeatForever(autoreverses: false)
            ) {
                pulseScale = 1.4
                pulseOpacity = 0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
