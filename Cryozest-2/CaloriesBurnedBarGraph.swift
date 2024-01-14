import SwiftUI

struct CaloriesBurnedGraphView: View {
    // Hardcoded data for calories burned
    let caloriesBurnedToday: CGFloat = 600
    let averageCaloriesBurned: CGFloat = 500

    // Maximum calories to scale the graph
    let maxCalories: CGFloat = 1000

    var body: some View {
        VStack(alignment: .leading) { // Left-aligned VStack
            Text("Calories Burned")
                .font(.headline)
                .foregroundColor(.white)

            ZStack(alignment: .leading) {
                // Bar for average calories burned
                Rectangle()
                    .frame(width: barWidth(for: averageCaloriesBurned), height: 20)
                    .foregroundColor(Color.green.opacity(0.5))
                    .cornerRadius(10)

                // Bar for today's calories burned
                Rectangle()
                    .frame(width: barWidth(for: caloriesBurnedToday), height: 20)
                    .foregroundColor(Color.green)
                    .cornerRadius(10)
            }

            // Labels for the calories data
            HStack {
                Label("Today: \(Int(caloriesBurnedToday)) cal", systemImage: "flame.fill")
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .padding()
        .background(Color.black) // Black background for contrast
    }

    private func barWidth(for calories: CGFloat) -> CGFloat {
        (calories / maxCalories) * UIScreen.main.bounds.width
    }
}
