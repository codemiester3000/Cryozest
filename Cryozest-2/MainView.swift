// MainView.swift - Segment 1
import SwiftUI

struct MainView: View {
    
    @Binding var sessions: [LogbookView.Session]
    
    @State private var temperature: String = ""
    @State private var humidity: String = ""
    @State private var bodyWeight: String = ""
    @State private var selectedTherapy: TherapyType = .drySauna
    @State private var timerLabel: String = "00:00"
    @State private var timer: Timer?
    @State private var timerDuration: TimeInterval = 0
    @State private var timerStartDate: Date?
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showLogbook: Bool = false
    @State private var showSessionSummary: Bool = false
    @State private var showPicker: Bool = false
    
    struct PickerButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .font(.headline)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
        }
    }
    
    // Custom dark color palette
    let darkBlue = Color(red: 10 / 255, green: 23 / 255, blue: 63 / 255)
    let darkGray = Color(red: 50 / 255, green: 56 / 255, blue: 62 / 255)
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Spacer()
                Image("Cryozest-1")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50*2)
                
                Text(timerLabel)
                    .font(.system(size: 48, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(spacing: 20) {
                    PrimaryButton(title: timer == nil ? "Start" : "Stop", action: startStopButtonPressed)
                    
                    CustomTextField(placeholder: "Temperature (F)", text: $temperature, keyboardType: .decimalPad)

                    CustomTextField(placeholder: "Humidity (%)", text: $humidity, keyboardType: .decimalPad)

                    CustomTextField(placeholder: "Body Weight (lbs)", text: $bodyWeight, keyboardType: .decimalPad)
                    
           
                    Button(action: {
                                            showPicker.toggle()
                                        }) {
                                            HStack {
                                                Text("Therapy Type")
                                                    .foregroundColor(.white)
                                                    .font(.headline)
                                                Spacer()
                                                Text(selectedTherapy.rawValue)
                                                    .foregroundColor(.white)
                                                    .font(.headline)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                                        }
                                        .actionSheet(isPresented: $showPicker) {
                                            ActionSheet(title: Text("Select Therapy Type"), buttons: TherapyType.allCases.map { therapyType in
                                                .default(Text(therapyType.rawValue)) {
                                                    selectedTherapy = therapyType
                                                }
                                            } + [.cancel()])
                                        }
                                    }
                                    .padding(.horizontal)
                     
            
                
                // MainView.swift - Navigation Links
                NavigationLink("", destination: LogbookView(sessions: $sessions), isActive: $showLogbook)
                    .hidden()
                NavigationLink("", destination: SessionSummary(duration: timerDuration, temperature: Int(temperature) ?? 0, humidity: Int(humidity) ?? 0, therapyType: selectedTherapy, bodyWeight: Double(bodyWeight) ?? 0, sessions: $sessions), isActive: $showSessionSummary)
                    .hidden()
            }
            .background(Color.darkBackground.edgesIgnoringSafeArea(.all))
            //.navigationBarTitle("Cryozest", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MainView.swift - Segment 4
    // The rest of the methods go here.
    
    func startStopButtonPressed() {
        // Timer has not started (shows 'start').
        if timer == nil {
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

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .font(.headline)
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
