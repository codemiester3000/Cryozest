import SwiftUI

struct WelcomeView: View {
    @State private var showNext = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            // Content overlay
            VStack(spacing: 30) { // Increased spacing
                
//                Image("TestLogo")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 250) // adjust this to change the logo size
//                    .padding(.vertical, 20)
                
                HardcodedGraph()
                
                Text("Welcome to CryoZest")
                    .font(.system(size: 30, weight: .bold, design: .default)) // Custom larger font size
                    .foregroundColor(.white) // Retaining the white color
                    .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 2) // Keeping the subtle shadow for depth
                    .padding(.top, 20) // Retaining the top padding
                    .multilineTextAlignment(.center) // Center alignment
                
                Divider().background(Color.darkBackground.opacity(0.8))
                    
                Spacer()
                
                HStack {
                    Spacer() // For center alignment
                    
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.red)
                        .imageScale(.medium) // Slightly reduced size for balance
                        .padding(.trailing, 8) // Spacing between icon and text
                    
                    Text("See your health metrics evolve as you develop new habits")
                        .font(.system(size: 16, weight: .bold, design: .default))
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
                        .foregroundColor(.red)
                        .imageScale(.medium) // Slightly reduced size for balance
                        .padding(.trailing, 8) // Spacing between icon and text
                    
                    Text("No data collected, ever")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2) // To prevent text overflow
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(.red)
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
                        .font(.footnote)
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

struct HardcodedGraph: View {
    // Hardcoded data for the last seven days and their recovery scores
    let lastSevenDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let recoveryScores = [70, 50, 30, 80, 60, 90, 40]

    var body: some View {
        ZStack {
            VStack {
//                HStack {
//                    Text("Recovery Per Day")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .padding(.horizontal)
//                    Spacer()
//                }
//                .padding(.horizontal)
//                .padding(.vertical)
                
                HStack(alignment: .bottom) {
                    ForEach(Array(zip(lastSevenDays, recoveryScores)), id: \.0) { (day, percentage) in
                        VStack {
//                            Text("\(percentage)%")
//                                .font(.caption)
//                                .foregroundColor(.white)
                            Rectangle()
                                .fill(getColor(forPercentage: percentage))
                                .frame(width: 40, height: CGFloat(percentage))
                                .cornerRadius(5)
//                            Text(day)
//                                .font(.caption)
//                                .foregroundColor(.white)
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
