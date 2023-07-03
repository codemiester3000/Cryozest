import SwiftUI

enum TherapyType: String, Codable, Identifiable, CaseIterable {
    case drySauna = "Sauna"
    case hotYoga = "Hot Yoga"
    case running = "Running"
    case weightTraining = "Lifting"
    case coldPlunge = "Cold Plunge"
    case coldShower = "Cold Shower"
    case iceBath = "Ice Bath"
    case coldYoga = "Yoga"
    case meditation = "Meditation"
    case stretching = "Stretching"
    case deepBreathing = "Deep Breathing"
    case sleep = "Sleep"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .drySauna:
            return "flame.fill"
        case .hotYoga:
            return "bolt.fill"
        case .running:
            return "figure.walk"
        case .weightTraining:
            return "dumbbell.fill"
        case .coldPlunge:
            return "snow"
        case .coldShower:
            return "drop.fill"
        case .iceBath:
            return "snowflake"
        case .coldYoga:
            return "leaf.arrow.circlepath"
        case .meditation:
            return "heart.fill"
        case .stretching:
            return "person.fill"
        case .deepBreathing:
            return "wind"
        case .sleep:
            return "moon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .drySauna, .hotYoga, .running, .weightTraining:
            return Color.orange
        case .coldPlunge, .coldShower, .iceBath, .coldYoga:
            return Color.blue
        case .meditation, .stretching, .deepBreathing, .sleep:
            return Color.green
        }
    }
}

