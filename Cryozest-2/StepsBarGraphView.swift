import SwiftUI

struct StepsBarGraphView: View {
    // Hardcoded data
    let stepsToday: CGFloat = 3000
    let averageSteps: CGFloat = 5000

    // Maximum steps to scale the graph
    let maxSteps: CGFloat = 10000

    var body: some View {
        VStack(alignment: .leading) { // Left-aligned VStack
            Text("Steps")
                .font(.headline)
                .foregroundColor(.white)

            ZStack(alignment: .leading) {
                // Bar for average steps
                Rectangle()
                    .frame(width: barWidth(for: averageSteps), height: 20)
                    .foregroundColor(Color.red.opacity(0.5))
                    .cornerRadius(10)

                // Bar for today's steps
                Rectangle()
                    .frame(width: barWidth(for: stepsToday), height: 20)
                    .foregroundColor(Color.red)
                    .cornerRadius(10)
            }

            // Labels for the steps
            HStack {
                Label("Today: \(Int(stepsToday))", systemImage: "figure.walk")
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .padding()
        .background(Color.black) // Black background for contrast
    }

    private func barWidth(for steps: CGFloat) -> CGFloat {
        (steps / maxSteps) * UIScreen.main.bounds.width
    }
}
