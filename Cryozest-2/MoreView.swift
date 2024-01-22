import SwiftUI

struct MoreView: View {
    @StateObject var userSettings = UserSettings()
    
    // TODO: We wont need any of these as we move them into the userSettings struct
    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var sex: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var trainingIntensity: String = "Maintaining"
    @State private var stepsGoal: Int = 10000
    @State private var remSleepGoal: Int = 90
    @State private var deepSleepGoal: Int = 90
    @State private var coreSleepGoal: Int = 90
    @State private var totalSleepGoal: Int = 8
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
                    HStack {
                        Text("Date of Birth")
                        Spacer()
                        Text("\(userDateOfBirth, formatter: dateFormatter)")
                            .foregroundColor(.gray)
                    }
                    
                    //                       HStack {
                    //                           Text("Sex")
                    //                           Spacer()
                    //                           Text(sex)
                    //                               .foregroundColor(.gray)
                    //                       }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        Text("\(Int(userHeight * 3.28084))' \(Int((userHeight * 3.28084 - Double(Int(userHeight * 3.28084))) * 12))\"")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(String(format: "%.0f lb", userWeight))")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Training Goal")) {
                                   Picker("Intensity", selection: $userSettings.trainingIntensity) {
                                       ForEach(["Tapering", "Maintaining", "Building"], id: \.self) { Text($0) }
                                   }
                    
                    Stepper("Recovery Minutes: \(userSettings.recoveryMinutesGoal)", value: $userSettings.recoveryMinutesGoal, in: 0...120)

                    Stepper("Conditioning Minutes: \(userSettings.conditioningMinutesGoal)", value: $userSettings.conditioningMinutesGoal, in: 0...120)
                    
                    Stepper("High Intensity Minutes: \(userSettings.highIntensityMinutesGoal)", value: $userSettings.highIntensityMinutesGoal, in: 0...120)
                    
                    Stepper("Steps Goal: \(userSettings.stepsGoal)", value: $userSettings.stepsGoal, in: 0...50000)
                }
                
                Section(header: Text("Sleep Goal")) {
                                  Stepper("REM Sleep Goal: \(userSettings.remSleepGoal) minutes", value: $userSettings.remSleepGoal, in: 0...360)
                                  Stepper("Deep Sleep Goal: \(userSettings.deepSleepGoal) minutes", value: $userSettings.deepSleepGoal, in: 0...360)
                                  Stepper("Core Sleep Goal: \(userSettings.coreSleepGoal) minutes", value: $userSettings.coreSleepGoal, in: 0...360)
                                  Stepper("Total Sleep Goal: \(userSettings.totalSleepGoal) hours", value: $userSettings.totalSleepGoal, in: 0...24)
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
// DateFormatter to format the date of birth
private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter
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
