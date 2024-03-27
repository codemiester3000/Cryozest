import Foundation

// Define the class RelevantDataForTherapy
class RelevantDataForTherapy {
    
    // Map of dates to resting heart rate
    var restingHeartRate: [Date: Int]
    
    // Map of dates to resting HRV (Heart Rate Variability)
    var restingHRV: [Date: Int]
    
    // Map of dates to SleepData struct
    var sleepData: [Date: SleepData]
    
    // Initializer to set up a new instance of RelevantDataForTherapy
    init(restingHeartRate: [Date: Int], restingHRV: [Date: Int], sleepData: [Date: SleepData]) {
        self.restingHeartRate = restingHeartRate
        self.restingHRV = restingHRV
        self.sleepData = sleepData
    }
    
    // Method to format all the data into a string
    func toString() -> String {
        var result = "RelevantDataForTherapy: \n"
        result += "Resting Heart Rate: \n"
        for (date, rate) in restingHeartRate {
            result += "- \(dateFormatter(date)): \(rate) bpm\n"
        }
        result += "Resting HRV: \n"
        for (date, hrv) in restingHRV {
            result += "- \(dateFormatter(date)): \(hrv) ms\n"
        }
        result += "Sleep Data: \n"
        for (date, sleep) in sleepData {
            result += "- \(dateFormatter(date)): Deep: \(sleep.deep) min, REM: \(sleep.rem) min "
        }
        return result
    }
    
    // Helper function to format Date objects into readable strings
    private func dateFormatter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
