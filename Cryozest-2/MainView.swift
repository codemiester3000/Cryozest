// MainView.swift - Segment 1
import SwiftUI
import HealthKit

//Modifier to create the gradient background
struct GradientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom) // Change the gradient colors
                .edgesIgnoringSafeArea(.all)
            content
        }
    }
}

struct MainView: View {
    
    let healthStore = HKHealthStore()
    let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    
    
    @Binding var sessions: [TherapySession]
    
    @State private var temperature: String = ""
    @State private var humidity: String = ""
    @State private var bodyWeight: String = ""
    @State private var timerLabel: String = "00:00"
    @State private var timer: Timer?
    @State private var timerDuration: TimeInterval = 0
    @State private var timerStartDate: Date?
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showLogbook: Bool = false
    @State private var showSessionSummary: Bool = false
    @State private var therapyType: TherapyType = .drySauna
    
    var body: some View {
        NavigationView {
            VStack() {
                Spacer()
                Text("CryoZest")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white)
                
                Text(timerLabel)
                    .font(.system(size: 72, weight: .bold, design: .monospaced)) // Change the font design and weight
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 18, leading: 36, bottom: 18, trailing: 36))
                    .background(Color.orange) // Change the background color
                    .cornerRadius(16)
                    .padding(.bottom, 30)
                    .padding(.top, 30)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10) // Add a shadow effect
                
                
                // TherapyType picker
                HStack {
                    Text("Therapy Type: ")
                        .foregroundColor(.white)
                        .font(.system(size: 16, design: .monospaced))
                    
                    Spacer()
                    
                    Picker(selection: $therapyType, label: HStack {
                        Text("Therapy Type")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, design: .monospaced))
                            .bold()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.orange)
                    }) {
                        ForEach(TherapyType.allCases) { therapyType in
                            Text(therapyType.rawValue)
                                .tag(therapyType)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .background(RoundedRectangle(cornerRadius: 8).fill(LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom)))
                    .padding(.trailing)
                    .accentColor(.orange)
                }
                .padding()
                
                
                Button(action: startStopButtonPressed) {
                    Text(timer == nil ? "Start" : "Stop")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 80)
                        .padding(.vertical, 16)
                        .background(Color.orange) // Change the button color
                        .cornerRadius(40)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10) // Add a shadow effect
                }
                
                
                Spacer()
                
                // MainView.swift - Navigation Links
                NavigationLink("", destination: LogbookView(), isActive: $showLogbook)
                    .hidden()
                NavigationLink("", destination: SessionSummary(duration: timerDuration, temperature: Double(temperature) ?? 0, therapyType: $therapyType, bodyWeight: Double(bodyWeight) ?? 0), isActive: $showSessionSummary)
                    .hidden()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    // MainView.swift - Segment 4
    // The rest of the methods go here.
    
    func startStopButtonPressed() {
        // Timer has not started (shows 'start').
        if timer == nil {
            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    HealthKitManager.shared.fetchBodyWeight { weight in
                        if let weight = weight {
                            self.bodyWeight = String(weight)
                        }
                    }
                } else {
                    showAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
                }
            }
            
            timerStartDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                timerDuration = Date().timeIntervalSince(timerStartDate!)
                let minutes = Int(timerDuration) / 60
                let seconds = Int(timerDuration) % 60
                timerLabel = String(format: "%02d:%02d", minutes, seconds)
            }
        } else { // Timer is running (shows 'stop').
            timer?.invalidate()
            timer = nil
            showSummary()
            timerLabel = "00:00"
        }
    }
    
    func showSummary() {
        // Show the session summary view
        withAnimation {
            showSessionSummary = true
        }
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var timerIcon: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if timerIcon {
                    Image(systemName: "timer")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.customBlue, Color.blue]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(40)
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
            )
        }
        .padding(.bottom, 8)
    }
}





struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(12)
            .keyboardType(keyboardType)
            .background(Color(.secondarySystemBackground))
            .foregroundColor(Color(.label))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
            .padding(.bottom, 8)
    }
}

// Add this extension to define the custom colors
extension Color {
    static let darkBackground = Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255)
    static let customBlue = Color(red: 30 / 255, green: 144 / 255, blue: 255 / 255)
}

