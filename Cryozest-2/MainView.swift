import SwiftUI
import HealthKit

struct MainView: View {
    let healthStore = HKHealthStore()
    let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
    
    @Binding var sessions: [TherapySession]
    
    @State private var timerLabel: String = "00:00"
    @State private var timer: Timer?
    @State private var healthDataTimer: Timer?
    @State private var timerDuration: TimeInterval = 0
    @State private var timerStartDate: Date?
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showLogbook: Bool = false
    @State private var showSessionSummary: Bool = false
    @State private var therapyType: TherapyType = .drySauna
    @State private var isRunning = false
    @State private var averageHeartRate: Double = 0.0
    @State private var averageSpo2: Double = 0.0
    @State private var averageRespirationRate: Double = 0.0
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("CryoZest")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white)
                
                Text(timerLabel)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 18, leading: 36, bottom: 18, trailing: 36))
                    .background(Color.orange)
                    .cornerRadius(16)
                    .padding(.bottom, 30)
                    .padding(.top, 30)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                
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
                        .background(Color.orange)
                        .cornerRadius(40)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                }
                
                Spacer()
                
                NavigationLink(destination: LogbookView(), isActive: $showLogbook) {
                    EmptyView()
                }
                NavigationLink(
                    destination: SessionSummary(
                        duration: timerDuration,
                        therapyType: $therapyType,
                        averageHeartRate: averageHeartRate,
                        averageSpo2: averageSpo2,
                        averageRespirationRate: averageRespirationRate
                    ),
                    isActive: $showSessionSummary
                ) {
                    EmptyView()
                }
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
    
    
    
    func startStopButtonPressed() {
        // Timer has not started (shows 'start').
        if timer == nil {
            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    // pullHealthData()
                } else {
                    showAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
                }
            }
            
            pullHealthData()
            timerStartDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                print("here")
                timerDuration = Date().timeIntervalSince(timerStartDate!)
                let minutes = Int(timerDuration) / 60
                let seconds = Int(timerDuration) % 60
                timerLabel = String(format: "%02d:%02d", minutes, seconds)
            }
        } else { // Timer is running (shows 'stop').
            timer?.invalidate()
            timer = nil
            healthDataTimer?.invalidate()
            healthDataTimer = nil
            showSummary()
            timerLabel = "00:00"
        }
    }
    
    func pullHealthData() {
        print("pulling health data")
        healthDataTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            print("pulling data after 5 seconds")
            let startDate = timerStartDate!
            let endDate = Date()
            
            HealthKitManager.shared.fetchHealthData(from: startDate, to: endDate) { healthData in
                if let healthData = healthData {
                    print("successfully called healthKitManager for data", healthData)
                    averageHeartRate = healthData.avgHeartRate  // This line was changed
                    averageSpo2 = healthData.avgSpo2
                    averageRespirationRate = healthData.avgRespirationRate
                }
            }
        }
    }
    
    
    
    //    func startStopButtonPressed() {
    //        // Timer has not started (shows 'start').
    //        if timer == nil {
    //            HealthKitManager.shared.requestAuthorization { success, error in
    //                if success {
    //                    pullHealthData()
    //                } else {
    //                    showAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
    //                }
    //            }
    //
    //            timerStartDate = Date()
    //            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    //                timerDuration = Date().timeIntervalSince(timerStartDate!)
    //                let minutes = Int(timerDuration) / 60
    //                let seconds = Int(timerDuration) % 60
    //                timerLabel = String(format: "%02d:%02d", minutes, seconds)
    //            }
    //        } else { // Timer is running (shows 'stop').
    //            timer?.invalidate()
    //            timer = nil
    //            showSummary()
    //            timerLabel = "00:00"
    //        }
    //    }
    //
    //    func pullHealthData() {
    //        print("pulling health data")
    //        HealthKitManager.shared.requestAuthorization { success, error in
    //            if success {
    //                print("inside success")
    //                timerStartDate = Date()
    //                timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
    //
    //                    print("pulling data after 5 seconds")
    //                    timerDuration = Date().timeIntervalSince(timerStartDate!)
    //                    let minutes = Int(timerDuration) / 60
    //                    let seconds = Int(timerDuration) % 60
    //                    timerLabel = String(format: "%02d:%02d", minutes, seconds)
    //
    //                    let startDate = timerStartDate!
    //                    let endDate = Date()
    //
    //                    HealthKitManager.shared.fetchHealthData(from: startDate, to: endDate) { healthData in
    //                        if let healthData = healthData {
    //                            averageHeartRate = healthData.minHeartRate
    //                            averageSpo2 = healthData.avgSpo2
    //                            averageRespirationRate = healthData.avgRespirationRate
    //                        }
    //                    }
    //                }
    //            } else {
    //                showAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
    //            }
    //        }
    //    }
    
    func showSummary() {
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

extension Color {
    static let darkBackground = Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255)
    static let customBlue = Color(red: 30 / 255, green: 144 / 255, blue: 255 / 255)
}

