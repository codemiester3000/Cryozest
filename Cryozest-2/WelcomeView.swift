import SwiftUI

struct WelcomeView: View {
    @State private var showNext = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(gradient: Gradient(colors: [Color.gray, Color.orange]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            // Content overlay
            VStack(spacing: 20) {
                Text("Welcome to Cryozest!")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                
                Text("Your personal therapy companion.")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showNext = true
                        appState.hasLaunchedBefore = true
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(Color.white))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 50)
                }
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showNext) {
            TherapyTypeSelectionView()
                .environmentObject(appState)
        }
    }
}
