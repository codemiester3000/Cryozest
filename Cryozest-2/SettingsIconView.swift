import SwiftUI

class SettingsIconViewModel: ObservableObject {
    @Published var rotationDegrees = 0.0
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            withAnimation {
                self?.rotationDegrees += 360
            }
        }
    }
}

struct SettingsIconView: View {
    @ObservedObject var viewModel = SettingsIconViewModel()

    var body: some View {
        Image(systemName: "gearshape.fill")
            .foregroundColor(.orange)
            .font(.title)
            .rotationEffect(.degrees(viewModel.rotationDegrees))
            //.offset(y: 20)
            .animation(.easeInOut(duration: 1), value: viewModel.rotationDegrees)
    }
}

