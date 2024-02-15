//
//  SecondOnboardingPage.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 2/15/24.
//

import SwiftUI

struct SecondOnboardingPage: View {
    
    let appState: AppState
    
    @State private var showNext = false
    @State private var requestedAccess = false
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func requestHealthKitAccess() {
        HealthKitManager.shared.requestAuthorization { success, error in
            if success {
                requestedAccess = true
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                if requestedAccess {
                    Text("Great! Now let's select the Habits and exercises you want to track and get insights for")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)
                        .padding(.bottom)
                        .padding(.horizontal)
                } else {
                    Text("Before we begin. We need your permission to access HealthKit data")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)
                        .padding(.bottom)
                        .padding(.horizontal)
                    
                    Text("Your data is your own. Cryozest does not store any of your data, it is all saved on your own device. We read this data solely to provide you with valuable insights")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        if (requestedAccess) {
                            showNext = true
                            appState.hasLaunchedBefore = true
                        } else {
                            requestHealthKitAccess()
                        }
                        
                        // TODO:
                        // appState.hasLaunchedBefore = true
                    }
                }) {
                    Text(requestedAccess ? "Choose your habits!" : "Connect to HealthKit")
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
                
                // TODO: Add a button here that when pressed triggers the auth request for healthkit. need a bool value to know if they gave us full auth or not.
                
                // TODO: If the user gave full auth then lets look at their workouts recorded on apple watch to preselect some therapy types for them.
            }
            
        }
//        .fullScreenCover(isPresented: $showNext) {
//            TherapyTypeSelectionView()
//                .environmentObject(appState)
//        }
    }
}
