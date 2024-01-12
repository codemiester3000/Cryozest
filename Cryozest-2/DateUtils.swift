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
        let startDate = Date()
        let datesInRange = getDatesForTimeFrame(timeFrame: timeFrame, fromStartDate: startDate)
        
        return sessions
            .filter { $0.therapyType == therapyType.rawValue && datesInRange.contains($0.date ?? Date()) }
            .compactMap { $0.date }
    }
    
    func datesWithoutTherapySessions(sessions: FetchedResults<TherapySessionEntity>, therapyType: TherapyType, timeFrame: TimeFrame) -> [Date] {
        let completedDates = completedSessionDatesForTimeFrame(sessions: sessions, therapyType: therapyType, timeFrame: timeFrame)
        let allDates = getDatesForTimeFrame(timeFrame: timeFrame, fromStartDate: Date())
        
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
                timeFrameDates.append(date)
            }
        }
        
        return timeFrameDates
    }
    
    func getDatesExcluding(excludeDates: [Date], inDates: [Date]) -> [Date] {
        return inDates.filter { !excludeDates.contains($0) }
    }
}
