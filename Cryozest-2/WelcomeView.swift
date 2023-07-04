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
            VStack(spacing: 30) { // Increased spacing
                
                Image("TestLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250) // adjust this to change the logo size
                    .padding(.vertical, 20)
                
                Text("Welcome to Cryozest!")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    
                Spacer()
                
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.red)
                        .imageScale(.large) // 20% larger
                    Text("See your health metrics evolve as you develop new habits.")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.red)
                        .imageScale(.large) // 20% larger
                }
                .padding()
                
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.black)
                        .imageScale(.large) // 20% larger
                    Text("No data collected, ever.")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Image(systemName: "lock.fill")
                        .foregroundColor(.black)
                        .imageScale(.large) // 20% larger
                }
                .padding()
                
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
                        .foregroundColor(.black)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 20)
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

