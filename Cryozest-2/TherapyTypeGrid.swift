import SwiftUI

class TherapyTypeSelection: ObservableObject {
    @Published var selectedTherapyType: TherapyType = .drySauna
}

struct TherapyTypeGrid: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    
    let selectedTherapyTypes: [TherapyType]
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 10) {
            ForEach(selectedTherapyTypes, id: \.self) { therapyType in
                Button(action: {
                    therapyTypeSelection.selectedTherapyType = therapyType
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(therapyTypeSelection.selectedTherapyType == therapyType
                                    ? therapyType.color.opacity(0.3)
                                    : Color.white.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: therapyType.icon)
                                .foregroundColor(therapyTypeSelection.selectedTherapyType == therapyType ? .white : therapyType.color)
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(therapyType.displayName(managedObjectContext))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(12)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(therapyTypeSelection.selectedTherapyType == therapyType
                                ? therapyType.color.opacity(0.2)
                                : Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        therapyTypeSelection.selectedTherapyType == therapyType
                                            ? therapyType.color.opacity(0.6)
                                            : Color.white.opacity(0.15),
                                        lineWidth: therapyTypeSelection.selectedTherapyType == therapyType ? 2 : 1
                                    )
                            )
                    )
                    .shadow(
                        color: therapyTypeSelection.selectedTherapyType == therapyType
                            ? therapyType.color.opacity(0.3)
                            : .clear,
                        radius: 8, x: 0, y: 4
                    )
                }
                .padding(.horizontal, 5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .padding(.top, 8)
        .onAppear {
            if !selectedTherapyTypes.contains(therapyTypeSelection.selectedTherapyType) {
                therapyTypeSelection.selectedTherapyType = selectedTherapyTypes.first ?? .drySauna
            }
        }
    }
}
