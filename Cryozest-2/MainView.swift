// MainView.swift - Segment 1
import SwiftUI

struct MainView: View {
    @State private var temperature: String = ""
    @State private var humidity: String = ""
    @State private var bodyWeight: String = ""
    @State private var selectedTherapy: TherapyType = .drySauna
    @State private var timerLabel: String = "00:00"
    @State private var timer: Timer?
    @State private var timerDuration: TimeInterval = 0
    @State private var timerStartDate: Date?
    @State private var sessions: [LogbookView.Session] = []
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
                                
                                HStack {
                                    Button(action: logSessionButtonPressed) {
                                        Text("Log Session")
                                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                            .font(.headline)
                                    }.padding([.leading, .bottom, .trailing])
                                    
                                    Button(action: { showLogbook = true }) {
                                        Text("View Logbook")
                                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                                            .background(darkGray)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                            .font(.headline)
                                    }.padding([.leading, .bottom, .trailing])
                                }
                                
                                NavigationLink("", destination: LogbookView(sessions: $sessions), isActive: $showLogbook)
                                    .hidden()
                                NavigationLink("", destination: SessionSummary(duration: timerDuration, waterIntake: (Double(bodyWeight) ?? 0.0) / 30 * (timerDuration / 900)), isActive: $showSessionSummary)
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
        if timer == nil {
            timerStartDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                timerDuration = Date().timeIntervalSince(timerStartDate!)
                let minutes = Int(timerDuration) / 60
                let seconds = Int(timerDuration) % 60
                timerLabel = String(format: "%02d:%02d", minutes, seconds)
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    
    

    func logSessionButtonPressed() {
        guard let temperatureValue = Double(temperature),
              let humidityValue = Double(humidity),
              let bodyWeightValue = Double(bodyWeight)
        else {
            showAlert(title: "Invalid Input", message: "Please enter valid numerical values for temperature, humidity, and body weight.")
            return
        }

        if temperatureValue < -89.2 || temperatureValue > 58 {
            showAlert(title: "Invalid Input", message: "Please enter a temperature value within Earth's limits.")
            return
        }

        if humidityValue < 0 || humidityValue > 100 {
            showAlert(title: "Invalid Input", message: "Please enter a humidity value within Earth's limits.")
            return
        }

        if bodyWeightValue < 0 {
            showAlert(title: "Invalid Input", message: "Please enter a valid body weight.")
            return
        }

        // Create a session object with the input data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let session = LogbookView.Session(date: dateFormatter.string(from: Date()), duration: timerDuration, temperature: Int(temperatureValue), humidity: Int(humidityValue), therapyType: selectedTherapy)

        // Add the session to the sessions array
        sessions.append(session)

        // Calculate water intake
        let waterIntake = (bodyWeightValue / 30) * (timerDuration / 900)

        // Reset the timer
        timer?.invalidate()
        timer = nil
        timerDuration = 0
        timerLabel = "00:00"

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
    
    struct SessionSummary: View {
        let duration: TimeInterval
        let waterIntake: Double
        
        var body: some View {
            VStack {
                Text("Session Summary")
                    .font(.title)
                    .padding()
                
                Text("Duration: \(durationFormatter(duration: duration))")
                    .padding()
                
                Text("Water Intake: \(String(format: "%.2f", waterIntake)) fl.oz.")
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Session Summary", displayMode: .inline)
        }
        
        func durationFormatter(duration: TimeInterval) -> String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}


        // Add this extension to define the custom colors
        extension Color {
            static let darkBackground = Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255)
            static let customBlue = Color(red: 30 / 255, green: 144 / 255, blue: 255 / 255)
        }


