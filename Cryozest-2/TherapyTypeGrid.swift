import SwiftUI

class TherapyTypeSelection: ObservableObject {
    @Published var selectedTherapyType: TherapyType = .drySauna
}

struct TherapyTypeGrid: View {
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    
    let selectedTherapyTypes: [TherapyType]
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 10) {
            ForEach(selectedTherapyTypes, id: \.self) { therapyType in
                Button(action: {
                    self.therapyTypeSelection.selectedTherapyType = therapyType
                }) {
                    HStack {
                        Image(systemName: therapyType.icon)
                            .foregroundColor(.white)
                        Text(therapyType.rawValue)
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50)
                    .background(self.therapyTypeSelection.selectedTherapyType == therapyType ?
                                therapyType.color
                                : Color(.gray))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .padding(.top, 8)
    }
}

