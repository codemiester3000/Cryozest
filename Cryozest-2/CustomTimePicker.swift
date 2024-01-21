import SwiftUI

struct CustomPicker: View {
    @Binding var selectedTimeFrame: TimeFrame
    
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                CustomPickerItem(timeFrame: timeFrame, isSelected: selectedTimeFrame == timeFrame)
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

    var body: some View {
        Text(timeFrame.displayString())
            .font(.headline)
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundColor(isSelected ? Color.orange : Color.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(isSelected ? Color.orange.opacity(0.2) : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
    }
}
