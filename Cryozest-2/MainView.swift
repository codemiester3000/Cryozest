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
    
    // Custom dark color palette
    let darkBlue = Color(red: 10 / 255, green: 23 / 255, blue: 63 / 255)
    let darkGray = Color(red: 50 / 255, green: 56 / 255, blue: 62 / 255)
    
    var body: some View {
        NavigationView {
            VStack {
                Text(timerLabel)
                    .font(.system(size: 48, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top)
                
                Button(action: startStopButtonPressed) {
                    Text(timer == nil ? "Start" : "Stop")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(darkBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.headline)
                }.padding()
                
                TextField("Temperature (F)", text: $temperature)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding()
                
                TextField("Humidity (%)", text: $humidity)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding()
                
                TextField("Body Weight (lbs)", text: $bodyWeight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding()
                // MainView.swift - Segment 2
                Picker(selection: $selectedTherapy, label: Text("Therapy Type")) {
                    ForEach(TherapyType.allCases) { therapyType in
                        Text(therapyType.rawValue).tag(therapyType)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                NavigationLink("", destination: LogbookView(sessions: $sessions), isActive: $showLogbook)
                    .hidden()
                NavigationLink("", destination: SessionSummary(duration: timerDuration, temperature: Int(temperature) ?? 0, humidity: Int(humidity) ?? 0, therapyType: selectedTherapy, bodyWeight: Double(bodyWeight) ?? 0, sessions: $sessions), isActive: $showSessionSummary)
                    .hidden()
                
                
                // MainView.swift - Segment 3
            }
            .padding()
            .background(Color.darkBackground)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle("Cryozest", displayMode: .inline)
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


// Add this extension to define the custom colors
extension Color {
    static let darkBackground = Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255)
    static let customBlue = Color(red: 30 / 255, green: 144 / 255, blue: 255 / 255)
}
