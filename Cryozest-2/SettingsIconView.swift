import SwiftUI

class SettingsIconViewModel: ObservableObject {
    @Published var rotationDegrees = 0.0
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            withAnimation {
                self?.rotationDegrees += 360
            }
        }
    }
}

struct SettingsIconView: View {
    @ObservedObject var viewModel = SettingsIconViewModel()
    private var colors: [Color] = [.orange, .blue, .green]
    @State private var currentColorIndex = 0

    var body: some View {
        HStack {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 32) // Reduced height for the pill
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(colors[currentColorIndex])
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(viewModel.rotationDegrees))
            }
            Spacer()
        }
        //.padding()
        //.background(Color.white) // Gray, slightly transparent background
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 1), value: viewModel.rotationDegrees)
//        .onReceive(viewModel.$rotationDegrees) { _ in
//            updateColor()
//        }
    }

    private func updateColor() {
        let newIndex = (currentColorIndex + 1) % colors.count
        withAnimation {
            currentColorIndex = newIndex
        }
    }
}
