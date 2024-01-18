import Foundation
import CoreData
import SwiftUI

class DateUtils {
    
    static let shared = DateUtils()
    private let calendar = Calendar.current
    
    private init() { }
    
    func completedSessionDates(sessions: FetchedResults<TherapySessionEntity>, therapyType: TherapyType) -> [Date] {
        return sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
    }
    
    func completedSessionDatesForTimeFrame(sessions: FetchedResults<TherapySessionEntity>, therapyType: TherapyType, timeFrame: TimeFrame) -> [Date] {
        let timeFrameDates = getDatesForTimeFrame(timeFrame: timeFrame, fromStartDate: Date())

        var completedSessionDates = [Date]()
        for session in sessions {
            if let sessionDate = session.date, session.therapyType == therapyType.rawValue {
                let sessionDateStartOfDay = calendar.startOfDay(for: sessionDate)
                if timeFrameDates.contains(sessionDateStartOfDay) {
                    completedSessionDates.append(sessionDateStartOfDay)
                }

                // Debugging: Print each session's date and check if it's within the time frame
                print("Session Date (Start of Day): \(sessionDateStartOfDay), Included in Time Frame: \(timeFrameDates.contains(sessionDateStartOfDay))")
            }
        }

        return completedSessionDates
    }

    
    func datesWithoutTherapySessions(sessions: FetchedResults<TherapySessionEntity>, therapyType: TherapyType, timeFrame: TimeFrame) -> [Date] {
        let completedDates = completedSessionDatesForTimeFrame(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        let allDates = getBaselineDatesForTimeFrame(timeFrame: timeFrame, fromStartDate: Date())
        
        return allDates.filter { !completedDates.contains($0) }
    }
    
    func getDatesForTimeFrame(timeFrame: TimeFrame, fromStartDate startDate: Date) -> [Date] {
        let numberOfDays: Int
        switch timeFrame {
        case .week:
            numberOfDays = 7
        case .month:
            numberOfDays = 30
        case .allTime:
            numberOfDays = 365
        }
        
        var timeFrameDates = [Date]()
        for day in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: -day, to: startDate) {
                let startOfDay = calendar.startOfDay(for: date)
                timeFrameDates.append(startOfDay)
            }
        }
        return timeFrameDates
    }
    
    func getBaselineDatesForTimeFrame(timeFrame: TimeFrame, fromStartDate startDate: Date) -> [Date] {
        let numberOfDays: Int
        switch timeFrame {
        case .week:
            numberOfDays = 30
        case .month:
            numberOfDays = 60
        case .allTime:
            numberOfDays = 90
        }
        
        var timeFrameDates = [Date]()
        for day in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: -day, to: startDate) {
                let startOfDay = calendar.startOfDay(for: date)
                timeFrameDates.append(startOfDay)
            }
        }
        return timeFrameDates
    }

    func getDatesExcluding(excludeDates: [Date], inDates: [Date]) -> [Date] {
        return inDates.filter { !excludeDates.contains($0) }
    }
}
