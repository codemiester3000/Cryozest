import SwiftUI

struct CustomPicker: View {
    @Binding var selectedTimeFrame: TimeFrame
    let backgroundColor: Color

    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                CustomPickerItem(timeFrame: timeFrame, isSelected: selectedTimeFrame == timeFrame, backgroundColor: backgroundColor)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            triggerHapticFeedback()
                            self.selectedTimeFrame = timeFrame
                        }
                    }
            }
        }
        .padding(.horizontal, 24)
    }
}

struct CustomPickerItem: View {
    let timeFrame: TimeFrame
    let isSelected: Bool
    let backgroundColor: Color

    var body: some View {
        Text(timeFrame.displayString())
            .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(isSelected ? backgroundColor : Color.white.opacity(0.08))
                    .shadow(color: isSelected ? backgroundColor.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? backgroundColor.opacity(0.3) : Color.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.0 : 0.95)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
