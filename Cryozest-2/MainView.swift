import SwiftUI

struct MainView: View {
    @State private var temperature: String = ""
    @State private var humidity: String = ""
    @State private var timerLabel: String = "00:00"
    @State private var timer: Timer?
    @State private var timerDuration: TimeInterval = 0
    @State private var timerStartDate: Date?
    @State private var sessions: [LogbookView.Session] = []
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showLogbook: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Temperature", text: $temperature)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding()
                
                TextField("Humidity", text: $humidity)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding()
                
                Text(timerLabel)
                    .font(.system(size: 48, design: .monospaced))
                
                Button(action: startStopButtonPressed) {
                    Text(timer == nil ? "Start" : "Stop")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }.padding()
                
                Button(action: logSessionButtonPressed) {
                    Text("Log Session")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }.padding()
                
                Button(action: { showLogbook = true }) {
                    Text("View Logbook")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }.padding()
                
                NavigationLink("", destination: LogbookView(sessions: $sessions), isActive: $showLogbook)
                    .hidden()
            }
            .padding()
            .navigationBarTitle("Cryozest", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // The rest of the methods go here.
    func startStopButtonPressed() {
        if timer == nil {
            // Start the timer
            timerStartDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.timerDuration += 1
                let minutes = Int(self.timerDuration) / 60
                let seconds = Int(self.timerDuration) % 60
                self.timerLabel = String(format: "%02d:%02d", minutes, seconds)
            }
        } else {
            // Stop the timer
            timer?.invalidate()
            timer = nil
            timerStartDate = nil
        }
    }
    
    func logSessionButtonPressed() {
        guard let temperatureValue = Double(temperature),
              let humidityValue = Double(humidity)
        else {
            showAlert(title: "Invalid Input", message: "Please enter valid numerical values for temperature and humidity.")
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
        
        // Create a session object with the input data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let session = LogbookView.Session(date: dateFormatter.string(from: Date()), duration: timerDuration, temperature: Int(temperatureValue), humidity: Int(humidityValue))
        
        // Add the session to the sessions array
        sessions.append(session)
        
        // Reset the timer
        timer?.invalidate()
        timer = nil
        timerDuration = 0
        timerLabel = "00:00"
        
        // Show the logbook view
        showLogbook = true
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    
}
