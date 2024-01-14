import SwiftUI

struct SleepBarGraphView: View {
    // Hardcoded data for sleep (in hours)
    let sleepToday: CGFloat = 6.5
    let averageSleep: CGFloat = 7.5

    // Maximum sleep hours to scale the graph
    let maxSleep: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading) { // Left-aligned VStack
            Text("Sleep")
                .font(.headline)
                .foregroundColor(.white)

            ZStack(alignment: .leading) {
                // Bar for average sleep
                Rectangle()
                    .frame(width: barWidth(for: averageSleep), height: 20)
                    .foregroundColor(Color.blue.opacity(0.5))
                    .cornerRadius(10)

                // Bar for today's sleep
                Rectangle()
                    .frame(width: barWidth(for: sleepToday), height: 20)
                    .foregroundColor(Color.blue)
                    .cornerRadius(10)
            }

            // Labels for the sleep data
            HStack {
                Label("Today: \(sleepToday, specifier: "%.1f") hrs", systemImage: "bed.double.fill")
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .padding()
        .background(Color.black) // Black background for contrast
    }

    private func barWidth(for sleepHours: CGFloat) -> CGFloat {
        (sleepHours / maxSleep) * UIScreen.main.bounds.width
    }
}
