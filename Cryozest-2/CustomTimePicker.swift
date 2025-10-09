import SwiftUI

struct CustomPicker: View {
    @Binding var selectedTimeFrame: TimeFrame
    let backgroundColor: Color
    
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                CustomPickerItem(timeFrame: timeFrame, isSelected: selectedTimeFrame == timeFrame, backgroundColor: backgroundColor)
                    .onTapGesture {
                        triggerHapticFeedback()
                        self.selectedTimeFrame = timeFrame
                    }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
}

struct CustomPickerItem: View {
    let timeFrame: TimeFrame
    let isSelected: Bool
    let backgroundColor: Color

    var body: some View {
        Text(timeFrame.displayString())
            .font(.system(size: 15, weight: isSelected ? .semibold : .medium, design: .rounded))
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? backgroundColor.opacity(0.3) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? backgroundColor.opacity(0.6) : Color.clear, lineWidth: isSelected ? 2 : 0)
            )
    }
}
