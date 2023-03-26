// MainView.swift - Segment 1
import SwiftUI
import HealthKit

struct MainView: View {
    
    let healthStore = HKHealthStore()
    
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
    @State private var startHeartRate: Double = 0.0
    @State private var endHeartRate: Double = 0.0
    
    
    // Custom dark color palette
    let darkBlue = Color(red: 10 / 255, green: 23 / 255, blue: 63 / 255)
    let darkGray = Color(red: 50 / 255, green: 56 / 255, blue: 62 / 255)
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text(timerLabel)
                    .font(.system(size: 48, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(spacing: 20) {
                    PrimaryButton(title: timer == nil ? "Start" : "Stop", action: startStopButtonPressed)
                    
                    CustomTextField(placeholder: "Temperature (F)", text: $temperature, keyboardType: .decimalPad)
                    
                    CustomTextField(placeholder: "Humidity (%)", text: $humidity, keyboardType: .decimalPad)
                    
                    CustomTextField(placeholder: "Body Weight (lbs)", text: $bodyWeight, keyboardType: .decimalPad)
                    
                    Picker(selection: $selectedTherapy, label: Text("Therapy Type")) {
                        ForEach(TherapyType.allCases) { therapyType in
                            Text(therapyType.rawValue)
                                .tag(therapyType)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(.blue)
                    .cornerRadius(8)
                    
                }
                .padding(.horizontal)
                
                Spacer()
                
                // MainView.swift - Navigation Links
                NavigationLink("", destination: LogbookView(), isActive: $showLogbook)
                    .hidden()
                NavigationLink("", destination: SessionSummary(duration: timerDuration, temperature: Int(temperature) ?? 0, humidity: Int(humidity) ?? 0, therapyType: selectedTherapy, bodyWeight: Double(bodyWeight) ?? 0, sessions: $sessions), isActive: $showSessionSummary)
                    .hidden()
            }
            .background(Color.darkBackground.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Cryozest", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MainView.swift - Segment 4
    // The rest of the methods go here.
    
    // MainView.swift - Segment 4
    // The rest of the methods go here.
    
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

    func startStopButtonPressed() {
        // Timer has not started (shows 'start').
        if timer == nil {
            let typesToShare: Set<HKSampleType> = []
            let typesToRead: Set<HKObjectType> = [
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .bodyMass)!,
                HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
                HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            ]
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if success {
                    fetchHeartRate()
                    fetchBodyWeight()
                    fetchSleepData()
                    fetchRespirationData()
                    fetchHRVData()
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
        }
    }
        
        func fetchHeartRate() {
            let heartRateType = HKSampleType.quantityType(forIdentifier: .heartRate)!
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                DispatchQueue.main.async {
                    guard let samples = samples as? [HKQuantitySample], let quantity = samples.last?.quantity else {
                        return
                    }
                    let heartRate = quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    print("Heart rate: \(heartRate)")
                }
            }
            healthStore.execute(query)
        }
        
        func fetchBodyWeight() {
            let weightType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
            let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                DispatchQueue.main.async {
                    guard let samples = samples as? [HKQuantitySample], let quantity = samples.last?.quantity else {
                        return
                    }
                    let weight = quantity.doubleValue(for: HKUnit.pound())
                    print("Body weight: \(weight) lbs")
                }
            }
            healthStore.execute(query)
        }
        
        func fetchSleepData() {
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            let query = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                DispatchQueue.main.async {
                    guard let samples = samples as? [HKCategorySample] else {
                        return
                    }
                    let sleepAnalysis = samples.map { sample in
                        let startDate = sample.startDate
                        let endDate = sample.endDate
                        let value = sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue ? "In Bed" : "Asleep"
                        return (startDate, endDate, value)
                    }
                    print("Sleep Analysis: \(sleepAnalysis)")
                }
            }
            healthStore.execute(query)
        }
        
        func fetchRespirationData() {
            let respirationType = HKSampleType.quantityType(forIdentifier: .respiratoryRate)!
            let query = HKSampleQuery(sampleType: respirationType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                DispatchQueue.main.async {
                    guard let samples = samples as? [HKQuantitySample], let quantity = samples.last?.quantity else {
                        return
                    }
                    let respiratoryRate = quantity.doubleValue(for: HKUnit.init(from: "count/min"))
                    print("Respiratory rate: \(respiratoryRate)")
                }
            }
            healthStore.execute(query)
        }
        
        func fetchHRVData() {
            let hrvType = HKSampleType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                DispatchQueue.main.async {
                    guard let samples = samples as? [HKQuantitySample], let quantity = samples.last?.quantity else {
                        return
                    }
                    let hrv = quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    print("HRV: \(hrv) ms")
                }
            }
            healthStore.execute(query)
        }
        
        func fetchBodyWeight1() {
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
        func fetchBodyWeightfromHealthKit1() {
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

