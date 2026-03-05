import SwiftUI
import CoreData

// Info sheet for the Insights tab
struct InsightsInfoSheet: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("About Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 30)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        InfoSection(
                            icon: "chart.bar.xaxis",
                            color: .orange,
                            title: "Top Correlations",
                            description: "See which habits have the biggest impact on your health metrics. We use Pearson correlation analysis with statistical significance testing."
                        )

                        InfoSection(
                            icon: "list.bullet.rectangle.portrait",
                            color: .green,
                            title: "Per-Habit Insights",
                            description: "Tap any habit card to see detailed health impacts - how it affects your sleep, HRV, heart rate, and more."
                        )

                        InfoSection(
                            icon: "chart.line.uptrend.xyaxis",
                            color: .cyan,
                            title: "Health Trends",
                            description: "Monitor week-over-week changes in your key health metrics including HRV, resting heart rate, and sleep duration."
                        )

                        InfoSection(
                            icon: "heart.fill",
                            color: .pink,
                            title: "Wellness Trends",
                            description: "Track your daily mood ratings and see which habits correlate with better days."
                        )

                        InfoSection(
                            icon: "clock.fill",
                            color: .purple,
                            title: "Data Quality",
                            description: "More data = better insights. Track habits for at least 5 days to see early signals, 14 days for full statistical confidence."
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct InfoSection: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
