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
            
            // Content overlay
            VStack(spacing: 1) {
                Spacer()
                Image("TestLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250) // adjust this to change the logo size
                    .padding(.vertical, 30)
                
                
                Text("Welcome to CryoZest")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 1)
                
                Spacer()
                
                Text("Where data drives wellness, enabling a healthier, data-informed you")
                    .font(.system(size: 17)) // replace 20 with your desired font size
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 1)
                
//                Text("Track therapies, compare to your baseline metrics, and discover the impact on your health - all through smart analysis.")
//                    .font(.subheadline)
//                    .foregroundColor(.white)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal)
//                    .padding(.vertical, 30)
//
                Spacer()

                Text("Track therapies while tapping into your Apple Watch data. Our smart system crafts personalized wellness guidance by comparing current progress to baseline health metrics, revealing impactful health insights")
                    .font(.system(size: 17)) // replace 20 with your desired font size
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                
                Text("Start a health journey with privacy ensured - no data stored, ever")
                    .font(.headline)
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
