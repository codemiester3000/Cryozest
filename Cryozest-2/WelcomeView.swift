import SwiftUI

struct WelcomeView: View {
    @State private var showNext = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(gradient: Gradient(colors: [Color.gray, Color.orange]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            // Orange circle in background
            VStack {
                Spacer()
                
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .offset(y: 150)
                
                Spacer()
            }
            
            // Content overlayr
            VStack(spacing: 1) {
                Spacer()
                Image("TestLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250) // adjust this to change the logo size
                    .padding(.vertical, 20)
                
                
                Text("Welcome to CryoZest")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 30)
                
                Text("We believe that health and wellbeing should be backed by solid data. We champion a data-centric approach to unlock and enhance your potential")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 30)
                
                Text("Cryozest pairs with your Apple Watch, transforming your activities and therapies into data-driven wellness recommendations that are tailor-made for you")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Text("Ready to begin your path to optimized health?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showNext = true
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
                        .padding(.vertical, 10)
                }
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 20)
            
            
            .fullScreenCover(isPresented: $showNext) {
                TherapyTypeSelectionView()
                    .environmentObject(appState)
                
            }
        }
    }
}

