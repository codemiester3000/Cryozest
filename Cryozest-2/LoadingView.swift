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
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()
        )
    }
}
