//
//  MetricsHighlightsView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 12/27/23.
//

import SwiftUI

class MetricsHighlightsViewModel: ObservableObject {
    
    // Average Heart Rate Values
    @Published var avgHeartRateTherapyDays: Double = 0.0
    @Published var avgHeartRateNonTherapyDays: Double = 0.0
    
    // Resting Heart Rate Values
    @Published var restingHeartRateTherapyDays: Double = 0.0
    @Published var restingHeartRateNonTherapyDays: Double = 0.0
    
    // Difference values as percentages
    @Published var restingHeartRateDifference: Double = 0.0
    @Published var avgHeartRateDifference: Double = 0.0
    
    @Published var therapyType: TherapyType {
        didSet {
            if oldValue != therapyType {
                fetchHeartRates()
            }
        }
    }
    
    @Published var timeFrame: TimeFrame {
        didSet {
            if oldValue != timeFrame {
                fetchHeartRates()
            }
        }
    }
    
    var sessions: FetchedResults<TherapySessionEntity>
    
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.therapyType = therapyType
        self.timeFrame = timeFrame
        self.sessions = sessions
        
        fetchHeartRates()
    }
    
    func fetchHeartRates() {
        let group = DispatchGroup()
        
        fetchrestingHeartRateTherapyDays(group: group)
        fetchrestingHeartRateNonTherapyDays(group: group)
    }
    
    private func fetchrestingHeartRateTherapyDays(group: DispatchGroup) {
        let completedSessionDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
        
        print("fetchrestingHeartRateTherapyDays ", completedSessionDates)
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.restingHeartRateTherapyDays = avgHeartRateExcluding
                self.calculateRestingHRDifference()
            } else {
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: completedSessionDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.avgHeartRateTherapyDays = avgHeartRateExcluding
                self.calculateAvgHRDifference()
            } else {
                // print("Owen here. Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
    }
    
    private func fetchrestingHeartRateNonTherapyDays(group: DispatchGroup) {
        let completedSessionDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
        let timeFrameDates = DateUtils.shared.getDatesForTimeFrame(timeFrame: timeFrame, fromStartDate: Date())
        let nonTherapyDates = DateUtils.shared.getDatesExcluding(excludeDates: completedSessionDates, inDates: timeFrameDates)
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: nonTherapyDates) { fetchedAvgHeartRateExcluding in
            if let fetchedAvgHeartRateExcluding = fetchedAvgHeartRateExcluding {
                self.restingHeartRateNonTherapyDays = fetchedAvgHeartRateExcluding
                self.calculateRestingHRDifference()
            } else {
                // print("Failed to fetch average heart rate excluding specific days.")
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: nonTherapyDates) { avgHeartRateExcluding in
            if let avgHeartRateExcluding = avgHeartRateExcluding {
                self.avgHeartRateNonTherapyDays = avgHeartRateExcluding
                self.calculateAvgHRDifference()
            } else {
            }
            group.leave()
        }
    }
    
    private func calculateRestingHRDifference() {
        if restingHeartRateTherapyDays != 0 {
            let differenceValue = (restingHeartRateTherapyDays - restingHeartRateNonTherapyDays) / restingHeartRateNonTherapyDays * 100
            restingHeartRateDifference = differenceValue
        }
    }
    
    private func calculateAvgHRDifference() {
        if avgHeartRateTherapyDays != 0 {
            let differenceValue = (avgHeartRateTherapyDays - avgHeartRateNonTherapyDays) / avgHeartRateNonTherapyDays * 100
            avgHeartRateDifference = differenceValue
        }
    }
}

struct MetricsHighlightsView: View {
    @ObservedObject var model: MetricsHighlightsViewModel
    
    var body: some View {
        VStack {
            HighlightBullet(type: "resting heart rate",
                            percentage: $model.restingHeartRateDifference,
                            therapyType: $model.therapyType, timeFrame: $model.timeFrame)
            
            HighlightBullet(type: "average heart rate",
                            percentage: $model.avgHeartRateDifference,
                            therapyType: $model.therapyType, timeFrame: $model.timeFrame)
        }
        .padding()
    }
}


struct HighlightBullet: View {
    var type: String
    @Binding var percentage: Double
    @Binding var therapyType: TherapyType
    @Binding var timeFrame: TimeFrame
    
    var body: some View {
        HStack {
            HStack {
                Text("•")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                (Text("You saw a ")
                    //.fontWeight(.bold)
                    .foregroundColor(.black) +
                 Text("\(percentage, specifier: "%.1f")%")
                    .fontWeight(.bold)
                    .foregroundColor(.black) +
                    //.foregroundColor(isGreen ? Color(red: 0.2, green: 0.5, blue: 0.2) : Color(red: 0.7, green: 0.0, blue: 0.0)) +
                 Text(" \(percentage >= 0.0 ? "increase" : "decrease") ")
                    .fontWeight(.bold)
                    .foregroundColor(.black) +
                 Text("in ")
                    //.fontWeight(.bold)
                    .foregroundColor(.black) +
                 Text("\(type) ")
                    .fontWeight(.bold)
                    .foregroundColor(.black) +
                 
                 Text("the \(timeFrame.displayString().lowercased()) on ")
                    //.fontWeight(.bold)
                    .foregroundColor(.black) +
                 
                 Text("\(therapyType.rawValue.lowercased()) ")
                    .fontWeight(.bold)
                    .foregroundColor(therapyType.color) +
                 Text("days")
                    //.fontWeight(.bold)
                    .foregroundColor(.black))
            }
        }
        .padding(.vertical, 12)
    }
}
