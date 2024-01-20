import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile Page")
                .foregroundColor(.white) // Setting the text color to white for better visibility on a black background
                // Add more content for your profile page here
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Expanding the VStack to fill the entire screen
        .background(Color.black) // Setting the background color to black
        .edgesIgnoringSafeArea(.all) // Making sure the background extends to the edges of the screen, including the safe areas
    }
}
