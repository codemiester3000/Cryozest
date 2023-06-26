import SwiftUI

struct HRVAnalysisView: View {
    @State private var latestHRV: String = "Loading..."
    @State private var averageHRV: String = "Loading..."
    @State private var maxHRV: String = "Loading..."
    @State private var minHRV: String = "Loading..."
    @State private var trend: String = "Loading..."
    
    var body: some View {
        VStack {
            Text("Heart Rate Variability")
                .font(.title)
                .padding()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Latest HRV: \(latestHRV) ms")
                Text("Average HRV (last 7 days): \(averageHRV) ms")
                Text("Max HRV (last 7 days): \(maxHRV) ms")
                Text("Min HRV (last 7 days): \(minHRV) ms")
                Text("Trend (last 7 days): \(trend)")
            }
            .font(.body)
            .padding()
        }
        .onAppear(perform: loadData)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func loadData() {
        let lastSevenDays = Array(0...6).map { Date().addingTimeInterval(-86400 * Double($0)) }
        //        HealthKitManager.shared.fetchLatestHRV { latest in
        //            if let latest = latest {
        //                self.latestHRV = String(format: "%.2f", latest)
        //            } else {
        //                self.latestHRV = "No data"
        //            }
        //        }
        HealthKitManager.shared.fetchAvgHRVForDays(days: lastSevenDays) { average in
            if let average = average {
                self.averageHRV = String(format: "%.2f", average)
            } else {
                self.averageHRV = "No data"
            }
        }
        HealthKitManager.shared.fetchMaxHRVForDays(days: lastSevenDays) { max in
            if let max = max {
                self.maxHRV = String(format: "%.2f", max)
            } else {
                self.maxHRV = "No data"
            }
        }
        HealthKitManager.shared.fetchMinHRVForDays(days: lastSevenDays) { min in
            if let min = min {
                self.minHRV = String(format: "%.2f", min)
            } else {
                self.minHRV = "No data"
            }
        }
        HealthKitManager.shared.fetchHRVTrendForDays(days: lastSevenDays) { trend in
            if let trend = trend {
                self.trend = trend.description
            } else {
                self.trend = "No data"
            }
        }
    }
}
