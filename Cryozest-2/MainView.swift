import SwiftUI
import HealthKit
import CoreData

struct MainView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: SelectedTherapy.entity(), sortDescriptors: []) private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    let healthStore = HKHealthStore()
    let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
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
    @State private var minHeartRate: Double = 1000.0
    @State private var maxHeartRate: Double = 0.0
    @State private var averageSpo2: Double = 0.0
    @State private var averageRespirationRate: Double = 0.0
    @State private var isHealthDataAvailable: Bool = false
    
    @State private var acceptedHealthKitPermissions: Bool = false
    
    var body: some View {
        let therapyTypes = selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType!) }
        
        NavigationView {
            VStack {
                //Spacer()
                Text("CryoZest")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.white)
                    .padding(.top, 75)
                
                LazyVGrid(columns: gridItems, spacing: 10) {
                    ForEach(therapyTypes, id: \.self) { selectedTherapyType in
                        Button(action: {
                            self.therapyType = selectedTherapyType
                        }) {
                            HStack {
                                Image(systemName: selectedTherapyType.icon)
                                    .foregroundColor(.white)
                                Text(selectedTherapyType.rawValue)
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50)
                            .background(self.therapyType == selectedTherapyType ? selectedTherapyType.color : Color.gray)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
                .padding(.top, 20)
                
                Text(timerLabel)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 18, leading: 36, bottom: 18, trailing: 36))
                    .background(self.therapyType.color)
                    .cornerRadius(16)
                    .padding(.bottom, 28)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                
                
                Button(action: startStopButtonPressed) {
                    Text(timer == nil ? "Start" : "Stop")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 80)
                        .padding(.vertical, 28)
                        .background(self.therapyType.color)
                        .cornerRadius(40)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                }
                
                
                Spacer()
                
                Text(isHealthDataAvailable ? "Health data from sessions is available only with an Apple Watch" : "Enable HealthKit permissions for Cyrozest to give you the full health tracking experience. Visit Settings --> Privacy --> Health to grant access.")
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 26)
                
                NavigationLink(destination: LogbookView(), isActive: $showLogbook) {
                    EmptyView()
                }
                NavigationLink(
                    destination: SessionSummary(
                        duration: timerDuration,
                        therapyType: $therapyType,
                        averageHeartRate: averageHeartRate,
                        averageSpo2: averageSpo2,
                        averageRespirationRate: averageRespirationRate,
                        minHeartRate: minHeartRate,
                        maxHeartRate: maxHeartRate
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
            .onAppear() {
                
                // On first load always have the first therapyType selected.
                if let firstTherapy = therapyTypes.first {
                    therapyType = firstTherapy
                }
                
                HealthKitManager.shared.requestAuthorization { success, error in
                    if success {
                        HealthKitManager.shared.areHealthMetricsAuthorized() { isAuthorized in
                            isHealthDataAvailable = isAuthorized
                        }
                    } else {
                        showAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
                    }
                }
            }
            .navigationBarItems(trailing: NavigationLink(destination: TherapyTypeSelectionView()) {
                SettingsIconView()
            })
        }
    }
    
    
    func startStopButtonPressed() {
        // Timer has not started (shows 'start').
        if timer == nil {
            HealthKitManager.shared.requestAuthorization { success, error in
                DispatchQueue.main.async {
                    if success {
                        // pullHealthData()
                        self.acceptedHealthKitPermissions = true
                    } else {
                        self.acceptedHealthKitPermissions = false
                        showAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
                    }
                }
            }
            
            timerStartDate = Date()
            pullHealthData()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
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
        healthDataTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            let startDate = timerStartDate!
            let endDate = Date()
            
            HealthKitManager.shared.fetchHealthData(from: startDate, to: endDate) { healthData in
                if let healthData = healthData {
                    averageHeartRate = healthData.avgHeartRate  // This line was changed
                    averageSpo2 = healthData.avgSpo2
                    averageRespirationRate = healthData.avgRespirationRate
                    minHeartRate = healthData.minHeartRate
                    maxHeartRate = healthData.maxHeartRate
                }
            }
        }
    }
    
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

extension Color {
    static let darkBackground = Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255)
    static let customBlue = Color(red: 30 / 255, green: 144 / 255, blue: 255 / 255)
}

