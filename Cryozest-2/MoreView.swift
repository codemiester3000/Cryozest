import SwiftUI

struct MoreView: View {
    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var sex: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var trainingIntensity: String = "Maintaining"
    @State private var recoveryMinutesGoal: Int = 30
    @State private var conditioningMinutesGoal: Int = 30
    @State private var highIntensityMinutesGoal: Int = 30
    @State private var stepsGoal: Int = 10000
    @State private var remSleepGoal: Int = 90
    @State private var deepSleepGoal: Int = 90
    @State private var coreSleepGoal: Int = 90
    @State private var totalSleepGoal: Int = 8 // Assuming the goal is set in hours
    @State private var customMaxHR: Bool = false
    @State private var maxHeartRate: Int = 177
    @State private var customRestingHR: Bool = false
    @State private var restingHeartRate: Int = 60
    @State private var userDateOfBirth: Date = Date()
    @State private var userHeight: Double = 0
    @State private var userWeight: Double = 0
    
    
    private var healthKitManager = HealthKitManager.shared
    
    func fetchHealthData() {
        healthKitManager.fetchUserDOB { dateOfBirth, error in
            DispatchQueue.main.async {
                if let dateOfBirth = dateOfBirth {
                    self.userDateOfBirth = dateOfBirth
                    print("Date of Birth: \(self.userDateOfBirth)")
                } else if let error = error {
                    print("Error fetching date of birth: \(error.localizedDescription)")
                }
            }
        }
        
        // Fetch Body Mass
        healthKitManager.fetchMostRecentBodyMass { bodyMass in
            DispatchQueue.main.async {
                if let bodyMass = bodyMass {
                    // Update userWeight directly
                    self.userWeight = bodyMass
                }
            }
        }
        
        // Fetch Height
        healthKitManager.fetchMostRecentHeight { height, error in
            DispatchQueue.main.async {
                if let height = height {
                    // Update userHeight directly
                    self.userHeight = height
                }
            }
        }
    }
    
    
    
    // Add other state variables as needed for HR zones, privacy policy, and feedback
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Details")) {
                    TextField("Name", text: $name)
                    // Use the fetched date of birth for the DatePicker
                    DatePicker("Date of Birth", selection: $userDateOfBirth, displayedComponents: .date)
                    Picker("Sex", selection: $sex) {
                        ForEach(["Male", "Female", "Other"], id: \.self) { Text($0) }
                    }
                    // Format and display height in feet and inches
                    Text("Height: \(Int(userHeight * 3.28084))' \(Int((userHeight * 3.28084 - Double(Int(userHeight * 3.28084))) * 12))\"")
                    // Format and display weight in pounds
                    Text("Weight: \(String(format: "%.2f lbs", userWeight))")
                }
                
                Section(header: Text("Training Goal")) {
                    Picker("Intensity", selection: $trainingIntensity) {
                        ForEach(["Tapering", "Maintaining", "Building"], id: \.self) { Text($0) }
                    }
                    Stepper("Recovery Minutes: \(recoveryMinutesGoal)", value: $recoveryMinutesGoal, in: 0...120)
                    Stepper("Conditioning Minutes: \(conditioningMinutesGoal)", value: $conditioningMinutesGoal, in: 0...120)
                    Stepper("High Intensity Minutes: \(highIntensityMinutesGoal)", value: $highIntensityMinutesGoal, in: 0...120)
                    Stepper("Steps Goal: \(stepsGoal)", value: $stepsGoal, in: 0...50000)
                }
                
                Section(header: Text("Sleep Goal")) {
                    Stepper("REM Sleep Goal: \(remSleepGoal) minutes", value: $remSleepGoal, in: 0...360)
                    Stepper("Deep Sleep Goal: \(deepSleepGoal) minutes", value: $deepSleepGoal, in: 0...360)
                    Stepper("Core Sleep Goal: \(coreSleepGoal) minutes", value: $coreSleepGoal, in: 0...360)
                    Stepper("Total Sleep Goal: \(totalSleepGoal) hours", value: $totalSleepGoal, in: 0...24)
                }
                
                Section(header: Text("Heart Rate Preferences")) {
                    Toggle("Use Custom Max Heart Rate", isOn: $customMaxHR)
                    if customMaxHR {
                        Stepper("Max Heart Rate: \(maxHeartRate)", value: $maxHeartRate, in: 100...220)
                    }
                    Toggle("Use Custom Resting Heart Rate", isOn: $customRestingHR)
                    if customRestingHR {
                        Stepper("Resting Heart Rate: \(restingHeartRate)", value: $restingHeartRate, in: 30...100)
                    }
                    // Implement manual adjustment of HR zones here
                }
                
                Section {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                    NavigationLink(destination: FeedbackView()) {
                        Text("Submit Feedback")
                    }
                }
            }
            .navigationTitle("More")
            .onAppear {
                fetchHealthData()
            }
            
        }
    }
}

// Placeholder for Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy Details")
        // Add the content of your Privacy Policy here
    }
}

// Placeholder for Feedback View
struct FeedbackView: View {
    @State private var feedback: String = ""
    
    var body: some View {
        Form {
            Text("We would love to hear your thoughts, concerns or problems with anything so we can improve!")
            TextEditor(text: $feedback)
                .frame(minHeight: 200)
            Button("Submit") {
                // Submit feedback
                // This would typically involve sending the feedback to a server or handling it according to your app's requirements
            }
        }
        .navigationTitle("Feedback")
    }
}

// Start the SwiftUI preview or main App with this view
struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView()
    }
}
