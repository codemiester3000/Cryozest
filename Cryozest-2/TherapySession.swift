// Session.swift

import SwiftUI

struct TherapySession: Codable, Identifiable {
    let id: UUID
    let date: String
    let duration: TimeInterval
    let temperature: Double
    let humidity: Int
    let therapyType: TherapyType
    let bodyWeight: Double
    
    init(date: String, duration: TimeInterval, temperature: Double, humidity: Int, therapyType: TherapyType, bodyWeight: Double) {
            self.id = UUID()
            self.date = date
            self.duration = duration
            self.temperature = temperature
            self.humidity = humidity
            self.therapyType = therapyType
            self.bodyWeight = bodyWeight
        }
        
        var formattedDuration: String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

