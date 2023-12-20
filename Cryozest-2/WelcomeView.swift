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
                
                Text("Welcome to CryoZest")
                    .font(.system(size: 40, weight: .bold, design: .default)) // Custom larger font size
                    .foregroundColor(.white) // Retaining the white color
                    .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 2) // Keeping the subtle shadow for depth
                    .padding(.top, 20) // Retaining the top padding
                    .multilineTextAlignment(.center) // Center alignment
                    
                Spacer()
                
                HStack {
                    Spacer() // For center alignment
                    
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.red)
                        .imageScale(.medium) // Slightly reduced size for balance
                        .padding(.trailing, 8) // Spacing between icon and text
                    
                    Text("See your health metrics evolve as you develop new habits")
                        .font(.system(size: 18, weight: .medium, design: .rounded)) // Adjusted for better readability
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2) // To prevent text overflow
                    
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.red)
                        .imageScale(.medium) // Synchronized with left icon
                        .padding(.leading, 8) // Consistent spacing

                    Spacer() // For center alignment
                }
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.2)) // Subtle background for emphasis
                .cornerRadius(10) // Rounded corners for a softer look
                .padding(.horizontal) // Ensures padding from screen edges

                
                HStack {
                    Spacer() // For center alignment
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(.black)
                        .imageScale(.medium) // Slightly reduced size for balance
                        .padding(.trailing, 8) // Spacing between icon and text
                    
                    Text("No data collected, ever")
                        .font(.system(size: 18, weight: .medium, design: .rounded)) // Adjusted for better readability
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2) // To prevent text overflow
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(.black)
                        .imageScale(.medium) // Synchronized with left icon
                        .padding(.leading, 8) // Consistent spacing

                    Spacer() // For center alignment
                }
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.2)) // Subtle background for emphasis
                .cornerRadius(10) // Rounded corners for a softer look
                .padding(.horizontal) // Ensures padding from screen edges
                
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

