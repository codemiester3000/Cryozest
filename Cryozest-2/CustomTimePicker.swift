import SwiftUI

struct CustomPicker: View {
    @Binding var selectedTimeFrame: TimeFrame
    let backgroundColor: Color
    
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                CustomPickerItem(timeFrame: timeFrame, isSelected: selectedTimeFrame == timeFrame, backgroundColor: backgroundColor)
                    .onTapGesture {
                        triggerHapticFeedback()
                        self.selectedTimeFrame = timeFrame
                    }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .shadow(color: Color.gray.opacity(0.5), radius: 10, x: 0, y: 5))
    }
}

struct CustomPickerItem: View {
    let timeFrame: TimeFrame
    let isSelected: Bool
    let backgroundColor: Color

    var body: some View {
        Text(timeFrame.displayString())
            .font(.headline)
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundColor(isSelected ? backgroundColor : Color.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(isSelected ? backgroundColor.opacity(0.2) : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? backgroundColor : Color.clear, lineWidth: 2)
            )
    }
}
