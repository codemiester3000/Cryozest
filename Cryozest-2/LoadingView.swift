import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header skeleton
            HStack(spacing: 12) {
                SkeletonCircle(size: 50)
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonLine(width: 150, height: 18)
                    SkeletonLine(width: 100, height: 14)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)

            // Main content cards
            VStack(spacing: 12) {
                SkeletonCard(height: 100)
                SkeletonCard(height: 120)
                SkeletonCard(height: 100)
                SkeletonCard(height: 140)
            }
            .padding(.horizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
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
            }
        )
    }
}
