import SwiftUI
import HealthKit
import CoreData

class MainViewModel: ObservableObject {
    @Published var therapyTypeSelection: TherapyTypeSelection
    @Published var timerLabel: String = "00:00"
    @Published var timerDuration: TimeInterval = 0
    @Published var timerStartDate: Date?
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showLogbook: Bool = false
    @Published var showSessionSummary: Bool = false
    @Published var therapyType: TherapyType = .drySauna
    @Published var isRunning = false
    @Published var averageHeartRate: Double = 0.0
    @Published var minHeartRate: Double = 1000.0
    @Published var maxHeartRate: Double = 0.0
    @Published var averageSpo2: Double = 0.0
    @Published var averageRespirationRate: Double = 0.0
    @Published var isHealthDataAvailable: Bool = false
    @Published var acceptedHealthKitPermissions: Bool = false
    @Published var countDown: Bool = false
    @Published var initialTimerDuration: TimeInterval = 0
    @Published var showCreateTimer = false
    
    var healthStore = HKHealthStore()
    let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
    
    var timer: Timer?
    var healthDataTimer: Timer?
    
    init(therapyTypeSelection: TherapyTypeSelection) {
        self.therapyTypeSelection = therapyTypeSelection
    }
    
    func startCountdown(for seconds: TimeInterval) {
        initialTimerDuration = seconds
        timerDuration = seconds
        countDown = true
        startStopButtonPressed()
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
                        // showAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
                    }
                }
            }
            
            timerStartDate = Date()
            pullHealthData()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if self.countDown {
                    self.timerDuration -= 1
                    if self.timerDuration <= 0 {
                        self.timer?.invalidate()
                        self.timer = nil
                        self.countDown = false
                        self.showSummary()
                        self.timerLabel = "00:00"
                        return
                    }
                } else {
                    self.timerDuration = Date().timeIntervalSince(self.timerStartDate!)
                }
                let minutes = Int(self.timerDuration) / 60
                let seconds = Int(self.timerDuration) % 60
                self.timerLabel = String(format: "%02d:%02d", minutes, seconds)
            }
        } else { // Timer is running (shows 'stop').
            timer?.invalidate()
            timer = nil
            healthDataTimer?.invalidate()
            healthDataTimer = nil
            showSummary()
            timerLabel = "00:00"
            
            // For stopwatch timers
            if countDown {
                timerDuration = initialTimerDuration - timerDuration
                countDown = false
            }
        }
    }
    
    func pullHealthData() {
        healthDataTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            let startDate = self.timerStartDate!
            let endDate = Date()
            
            HealthKitManager.shared.fetchHealthData(from: startDate, to: endDate) { healthData in
                if let healthData = healthData {
                    self.averageHeartRate = healthData.avgHeartRate  // This line was changed
                    self.averageSpo2 = healthData.avgSpo2
                    self.averageRespirationRate = healthData.avgRespirationRate
                    self.minHeartRate = healthData.minHeartRate
                    self.maxHeartRate = healthData.maxHeartRate
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

struct MainView: View {
    
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    
    
    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    @FetchRequest(
        entity: CustomTimer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomTimer.duration, ascending: true)]
    )
    private var customTimers: FetchedResults<CustomTimer>
    
    var selectedTherapyTypes: [TherapyType] {
        // Convert the selected therapy types from strings to TherapyType values
        if selectedTherapies.isEmpty {  
            return [.drySauna, .weightTraining, .coldPlunge, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }
    
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [])
    private var sessions: FetchedResults<TherapySessionEntity>
    
    init(therapyTypeSelection: TherapyTypeSelection) {
        self.therapyTypeSelection = therapyTypeSelection
        self.viewModel = MainViewModel(therapyTypeSelection: therapyTypeSelection)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("CryoZest")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.white)
                    .padding(.top, 35)
                
                TherapyTypeGrid(therapyTypeSelection: therapyTypeSelection, selectedTherapyTypes: selectedTherapyTypes)
                    .padding(.bottom, 18)
                
                Text(viewModel.timerLabel)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 18, leading: 36, bottom: 18, trailing: 36))
                    .background(self.therapyTypeSelection.selectedTherapyType.color)
                    .cornerRadius(16)
                    .padding(.bottom, 28)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                
                HStack(spacing: 10) {
                    ForEach(customTimers, id: \.self) { timer in
                        Button(action: {
                            viewModel.startCountdown(for: Double(timer.duration) * 60)
                        }) {
                            Text("\(timer.duration) min")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(self.therapyTypeSelection.selectedTherapyType.color)
                                .cornerRadius(40)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                        }
                        .disabled(viewModel.timer != nil)
                        .opacity(viewModel.timer != nil ? 0.3 : 1)
                    }
                    Button(action: {
                        // Navigate to a view for creating a new custom timer
                        viewModel.showCreateTimer = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(self.therapyTypeSelection.selectedTherapyType.color)
                            .cornerRadius(40)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                    }
                    .disabled(viewModel.timer != nil)
                    .opacity(viewModel.timer != nil ? 0.3 : 1)
                    
                }
                .padding(.bottom, 28)
                
                Button(action: viewModel.startStopButtonPressed) {
                    Text(viewModel.timer == nil ? "Start" : "Stop")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 80)
                        .padding(.vertical, 28)
                        .background(self.therapyTypeSelection.selectedTherapyType.color)
                        .cornerRadius(40)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                }
                
                
                Spacer()
                
                Text(viewModel.isHealthDataAvailable ? "Health data from sessions is available only with an Apple Watch" : "Enable HealthKit permissions for Cyrozest to give you the full health tracking experience. Visit Settings --> Privacy --> Health to grant access.")
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 26)
                
                NavigationLink(destination: LogbookView(therapyTypeSelection: self.therapyTypeSelection), isActive: $viewModel.showLogbook) {
                    EmptyView()
                }
                NavigationLink(
                    destination: SessionSummary(
                        duration: viewModel.timerDuration,
                        therapyType: $viewModel.therapyType,
                        averageHeartRate: viewModel.averageHeartRate,
                        averageSpo2: viewModel.averageSpo2,
                        averageRespirationRate: viewModel.averageRespirationRate,
                        minHeartRate: viewModel.minHeartRate,
                        maxHeartRate: viewModel.maxHeartRate
                    ),
                    isActive: $viewModel.showSessionSummary
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
                
                // Add default timers if no custom ones are saved
                if customTimers.isEmpty {
                    let defaultDurations = [5, 10, 15]
                    for duration in defaultDurations {
                        let newTimer = CustomTimer(context: viewContext)
                        newTimer.duration = Int32(duration)
                    }
                }
                
                do {
                    try viewContext.save()
                } catch {
                    // Handle the error appropriately
                    print("Failed to save new timers: \(error)")
                }
                
                // On first load always have the first therapyType selected.
                if let firstTherapy = selectedTherapyTypes.first {
                    viewModel.therapyType = firstTherapy
                }
                
                HealthKitManager.shared.requestAuthorization { success, error in
                    if success {
                        HealthKitManager.shared.areHealthMetricsAuthorized() { isAuthorized in
                            viewModel.isHealthDataAvailable = isAuthorized
                        }
                    } else {
                        // showAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateTimer) {
                CreateTimerView()
                    .environment(\.managedObjectContext, self.viewContext)
            }
            .navigationBarItems(trailing: NavigationLink(destination: TherapyTypeSelectionView()) {
                SettingsIconView().id(UUID())
            })
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                // App has returned to the foreground, load timer state
                let now = Date()
                let timerStartDate = UserDefaults.standard.object(forKey: "timerStartDate") as? Date ?? now
                let initialTimerDuration = UserDefaults.standard.double(forKey: "timerDuration")
                let elapsedTime = now.timeIntervalSince(timerStartDate)
                let remainingTime = max(0, initialTimerDuration - elapsedTime)
                
                if remainingTime > 0 {
                    // Timer was running when app went to background
                    viewModel.timerStartDate = timerStartDate
                    viewModel.timerDuration = remainingTime
                } else {
                    // Timer was not running
                    viewModel.timerStartDate = nil
                    viewModel.timerDuration = 0
                }
                
            case .inactive, .background:
                // App has gone to the background, save timer state
                UserDefaults.standard.set(viewModel.timerStartDate, forKey: "timerStartDate")
                UserDefaults.standard.set(viewModel.initialTimerDuration, forKey: "timerDuration")
                
            @unknown default:
                // Future cases
                break
            }
        }
    }
}
