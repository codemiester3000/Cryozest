//
//  MockDataHelper.swift
//  Cryozest-2
//
//  TEMPORARY FILE FOR UI TESTING - DELETE THIS FILE WHEN DONE
//

import Foundation

struct MockDataHelper {
    // SET THIS TO false TO DISABLE MOCK DATA
    static let useMockData = false

    // Heart Rate Mock Data
    static let mockHeartRate = 62
    static let mockAverageHeartRate = 65

    // Steps Mock Data
    static let mockSteps = 8543

    // Water Intake Mock Data
    static let mockWaterCups = 5

    // Exertion Mock Data
    static let mockActiveMinutes = 42
    static let mockLightMinutes = 15.0
    static let mockModerateMinutes = 25.0
    static let mockVigorousMinutes = 7.0

    // Recovery/Sleep Mock Data
    static let mockRecoveryScore = 78
    static let mockSleepHours = 7.2
}
