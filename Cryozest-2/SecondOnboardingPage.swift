//
//  SecondOnboardingPage.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 2/15/24.
//

import SwiftUI

struct SecondOnboardingPage: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Before we begin. We need permission access to your HealthKit to give you insights")
                
                Text("Your data is your own. Cryozest does not store any of your data, it is all saved on your own device.")
                
                // TODO: Add a button here that when pressed triggers the auth request for healthkit. need a bool value to know if they gave us full auth or not.
                
                // TODO: If the user gave full auth then lets look at their workouts recorded on apple watch to preselect some therapy types for them. 
            }
        }
    }
}
