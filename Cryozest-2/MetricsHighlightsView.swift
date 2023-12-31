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
            
            HStack(alignment: .center) {
                Text("Highlights")
                    .font(.system(size: 24, weight: .regular, design: .default))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                Spacer()
                Text(model.timeFrame.displayString())
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(model.therapyType.color)
                    .cornerRadius(8)
            }
            .padding(.top)
            
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
            Text("•")
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading) {
                percentageText
                additionalText
            }
        }
        .padding(.vertical, 12)
    }

    private var percentageText: Text {
        Text("You saw a ")
            .font(.footnote)
            .foregroundColor(.white) +
        Text("\(percentage, specifier: "%.1f")%")
            .fontWeight(.bold)
            .font(.footnote)
            .foregroundColor(.white) +
        Text(" \(percentage >= 0.0 ? "increase" : "decrease") ")
            .fontWeight(.bold)
            .font(.footnote)
            .foregroundColor(.white)
    }

    private var additionalText: Text {
        Text("in ")
            .font(.footnote)
            .foregroundColor(.white) +
        Text("\(type) ")
            .fontWeight(.bold)
            .font(.footnote)
            .foregroundColor(.white) +
        Text("the \(timeFrame.displayString().lowercased()) on ")
            .font(.footnote)
            .foregroundColor(.white) +
        Text("\(therapyType.rawValue.lowercased()) ")
            .fontWeight(.bold)
            .font(.footnote)
            .foregroundColor(therapyType.color) +
        Text("days")
            .font(.footnote)
            .foregroundColor(.white)
    }
}

