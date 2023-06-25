import SwiftUI

struct SettingsIconView: View {
    @State private var rotationDegrees = 0.0

        let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

        var body: some View {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.orange)
                .font(.title)
                .rotationEffect(.degrees(rotationDegrees))
                .offset(y: 20)
                .animation(.easeInOut(duration: 1), value: rotationDegrees)
//                .onAppear {
//                    withAnimation {
//                        rotationDegrees += 360
//                    }
//                }
                .onReceive(timer) { _ in
                    withAnimation {
                        rotationDegrees += 360
                    }
                }
        }
}
