//import SwiftUI
//
//class TherapyTypeSelection: ObservableObject {
//    @Published var selectedTherapyType: TherapyType = .drySauna
//}
//
//struct TherapyTypeGrid: View {
//    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
//    
//    let selectedTherapyTypes: [TherapyType]
//    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
//    
//    var body: some View {
//        LazyVGrid(columns: gridItems, spacing: 10) {
//            ForEach(selectedTherapyTypes, id: \.self) { therapyType in
//                Button(action: {
//                    self.therapyTypeSelection.selectedTherapyType = therapyType
//                }) {
//                    HStack {
//                        Image(systemName: therapyType.icon)
//                            .foregroundColor(.white)
//                        Text(therapyType.rawValue)
//                            .font(.system(size: 15, design: .monospaced))
//                            .foregroundColor(.white)
//                    }
//                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50)
//                    .background(self.therapyTypeSelection.selectedTherapyType == therapyType ?
//                                therapyType.color
//                                : Color(.gray))
//                    .cornerRadius(8)
//                }
//                .padding(.horizontal, 5)
//            }
//        }
//        .padding(.horizontal, 10)
//        .padding(.bottom, 8)
//        .padding(.top, 8)
//        .onAppear {
//            if !selectedTherapyTypes.contains(therapyTypeSelection.selectedTherapyType) {
//                therapyTypeSelection.selectedTherapyType = selectedTherapyTypes.first ?? .drySauna
//            }
//        }
//    }
//}
//

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
                    therapyTypeSelection.selectedTherapyType = therapyType
                }) {
                    HStack {
                        Image(systemName: therapyType.icon)
                            .foregroundColor(therapyTypeSelection.selectedTherapyType == therapyType ? .white : therapyType.color)
                            .font(.system(size: 20))
                        Text(therapyType.rawValue)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(therapyTypeSelection.selectedTherapyType == therapyType ? .white : therapyType.color)
                    }
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50)
                    .background(therapyTypeSelection.selectedTherapyType == therapyType ? therapyType.color : Color(.systemGray4))
                    .cornerRadius(10)
                    .shadow(color: therapyType.color.opacity(0.3), radius: 5, x: 0, y: 2)
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


//import SwiftUI
//
//class TherapyTypeSelection: ObservableObject {
//    @Published var selectedTherapyType: TherapyType = .drySauna
//}
//
//struct TherapyTypeGrid: View {
//    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
//    
//    let selectedTherapyTypes: [TherapyType]
//    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
//    
//    var body: some View {
//        LazyVGrid(columns: gridItems, spacing: 10) {
//            ForEach(selectedTherapyTypes, id: \.self) { therapyType in
//                Button(action: {
//                    therapyTypeSelection.selectedTherapyType = therapyType
//                }) {
//                    VStack {
//                        Image(systemName: therapyType.icon)
//                            .font(.title2)
//                            .foregroundColor(therapyTypeSelection.selectedTherapyType == therapyType ? .white : .gray)
//                        Text(therapyType.rawValue)
//                            .font(.subheadline)
//                            .foregroundColor(therapyTypeSelection.selectedTherapyType == therapyType ? .white : .gray)
//                    }
//                    .padding()
//                    .frame(minWidth: 0, maxWidth: .infinity)
//                    .background(therapyTypeSelection.selectedTherapyType == therapyType ? therapyType.color : Color(.gray))
//                    .cornerRadius(10)
//                    .shadow(radius: 2)
//                }
//                .padding(.horizontal, 5)
//            }
//        }
//        .padding(.horizontal, 10)
//        .padding(.bottom, 8)
//        .padding(.top, 8)
//        .onAppear {
//            if !selectedTherapyTypes.contains(therapyTypeSelection.selectedTherapyType) {
//                therapyTypeSelection.selectedTherapyType = selectedTherapyTypes.first ?? .drySauna
//            }
//        }
//    }
//}


