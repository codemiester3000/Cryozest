import SwiftUI

struct WelcomeView: View {
    @State private var showNext = false
    @State private var icon1Opacity = 0.0
    @State private var icon2Opacity = 0.0
    @State private var icon3Opacity = 0.0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                HardcodedGraph()
                
                Text("Welcome to CryoZest")
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 2)
                    .padding(.top, 20)
                    .multilineTextAlignment(.center)
                
                Divider().background(Color.darkBackground.opacity(0.8))
                
                HStack {
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 50))
                        .padding(.trailing, 8)
                        .opacity(icon1Opacity)
                    
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 50))
                        .padding(.trailing, 8)
                        .opacity(icon2Opacity)
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 50))
                        .padding(.leading, 8)
                        .opacity(icon3Opacity)

                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.0)) {
                        icon1Opacity = 1.0
                    }
                    withAnimation(Animation.easeIn(duration: 1.0).delay(0.3)) {
                        icon2Opacity = 1.0
                    }
                    withAnimation(Animation.easeIn(duration: 1.0).delay(0.6)) {
                        icon3Opacity = 1.0
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Text("CryoZest connects to your Apple Watch to see how your health and sleep change as you record your exercises")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)

                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showNext = true
                        
                        // TODO:
                        // appState.hasLaunchedBefore = true
                    }
                }) {
                    Text("Get Started!")
                        .font(.system(size: 14))
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
            SecondOnboardingPage(appState: appState)
            
//            TherapyTypeSelectionView()
//                .environmentObject(appState)
        }
    }
}

struct HardcodedGraph: View {
    // Hardcoded data for the last seven days and their recovery scores
    let lastSevenDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let recoveryScores = [70, 50, 30, 80, 60, 90, 40]

    var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .bottom) {
                    ForEach(Array(zip(lastSevenDays, recoveryScores)), id: \.0) { (day, percentage) in
                        VStack {
                            Rectangle()
                                .fill(getColor(forPercentage: percentage))
                                .frame(width: 40, height: CGFloat(percentage))
                                .cornerRadius(5)
                        }
                    }
                }
            }
        }
        .frame(height: 200) // Adjust the height as needed
    }
    
    // Function to get color based on percentage
    func getColor(forPercentage percentage: Int) -> Color {
        switch percentage {
        case let x where x > 50:
            return .green
        case let x where x > 30:
            return .yellow
        default:
            return .red
        }
    }
}
