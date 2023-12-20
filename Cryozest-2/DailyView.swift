import SwiftUI

struct LineGraph: View {
    var body: some View {
        HStack(spacing: 75) { // Spacing of 20 pixels between each line
            ForEach(0..<5) { _ in // Repeat 5 times for 5 lines
                Rectangle()
                    .fill(Color.gray.opacity(0.2)) // Light gray color
                    .frame(width: 1, height: 300) // 1 pixel wide and 300 pixels tall
            }
        }
    }
}

struct DailyView: View {
    var body: some View {
        VStack(spacing: 0) {
            LineGraph()
        }
        .edgesIgnoringSafeArea(.all) // Ensure it takes the full screen width
    }
}
