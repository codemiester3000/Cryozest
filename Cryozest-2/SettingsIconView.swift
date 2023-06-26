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
        Image(systemName: "gearshape.fill")
            .foregroundColor(colors[currentColorIndex])
            .font(.title)
            .rotationEffect(.degrees(viewModel.rotationDegrees))
            //.offset(y: 20)
            .animation(.easeInOut(duration: 1), value: viewModel.rotationDegrees)
            .onReceive(viewModel.$rotationDegrees) { _ in
                updateColor()
            }
    }

    private func updateColor() {
        let newIndex = (currentColorIndex + 1) % colors.count
        withAnimation {
            currentColorIndex = newIndex
        }
    }
}


