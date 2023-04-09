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
    @State private var progressValue: CGFloat = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 50) {
                
                // CryoZest Title
                
                Spacer()
                           Text("CryoZest")
                               .font(.system(size: 36, weight: .bold, design: .rounded))
                               .foregroundColor(Color.white)

                           // Hot & Cold Therapy Subtitle
                           Text("Hot & Cold Therapy")
                               .font(.system(size: 18, weight: .regular, design: .rounded))
                               .foregroundColor(Color.white)
                
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .mask(
                        Text(timerLabel)
                            .font(.system(size: 72, weight: .thin, design: .rounded)) // Change the font weight to .thin
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                
                Button(action: startStopButtonPressed) {
                    Text(timer == nil ? "Start" : "Stop")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 80)
                        .padding(.vertical, 16)
                        .background(Color.orange) // Change the button color
                        .cornerRadius(40)
                }
            
                Spacer()
            
                // MainView.swift - Navigation Links
                NavigationLink("", destination: LogbookView(), isActive: $showLogbook)
                    .hidden()
                NavigationLink("", destination: SessionSummary(duration: timerDuration, temperature: Double(temperature) ?? 0, therapyType: .drySauna, bodyWeight: Double(bodyWeight) ?? 0), isActive: $showSessionSummary)
                    .hidden()
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all)) 
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
            healthStore.requestAuthorization(toShare: [], read: [HKObjectType.quantityType(forIdentifier: .bodyMass)!, sleepAnalysisType, heartRateType, hrvType, respirationRateType]) { success, error in
                if success {
                    fetchBodyWeight()
                    fetchSleepAnalysis()
                    fetchHeartRate()
                    fetchHRV()
                    fetchRespirationRate()
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
    
    func fetchBodyWeight() {
        let weightType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            DispatchQueue.main.async {
                guard let samples = samples as? [HKQuantitySample], let quantity = samples.first?.quantity else {
                    return
                }
                let weight = quantity.doubleValue(for: HKUnit.pound())
                bodyWeight = String(weight)
            }
        }
        healthStore.execute(query)
    }
    
    func fetchSleepAnalysis() {
        let query = HKSampleQuery(sampleType: sleepAnalysisType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKCategorySample], let sleepSample = results.first else {
                // Handle error here
                return
            }
            
            // Process sleepSample here
        }
        healthStore.execute(query)
    }
    
    func fetchHeartRate() {
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let heartRateSample = results.first else {
                // Handle error here
                return
            }
            
            let heartRate = heartRateSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            
            // Process heartRate here
        }
        healthStore.execute(query)
    }
    
    func fetchHRV() {
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let hrvSample = results.first else {
                // Handle error here
                return
            }
            
            let hrv = hrvSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            
            // Process hrv here
        }
        healthStore.execute(query)
    }
    
    func fetchRespirationRate() {
        let query = HKSampleQuery(sampleType: respirationRateType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let respirationRateSample = results.first else {
                // Handle error here
                return
            }
            
            let respirationRate = respirationRateSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            
            // Process respirationRate here
        }
        healthStore.execute(query)
    }
    
    func fetchBodyWeightfromHealthKit() {
        let type = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let weight = results.first?.quantity.doubleValue(for: .pound()) else {
                // Handle error here
                return
            }
            DispatchQueue.main.async {
                bodyWeight = String(format: "%.1f", weight)
            }
        }
        healthStore.execute(query)
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

