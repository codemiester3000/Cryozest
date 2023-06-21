import Foundation

enum TherapyType: String, Codable, Identifiable, CaseIterable {
    case drySauna = "Sauna"
    case hotYoga = "Hot Yoga"
    case coldPlunge = "Cold Plunge"
    case meditation = "Meditation"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .drySauna:
            return "flame.fill" // Suggests heat
        case .hotYoga:
            return "leaf.fill" // Suggests steam
        case .coldPlunge:
            return "thermometer.snowflake" // Suggests cold water
        case .meditation:
            return "drop.fill" // Suggests a shower
        }
    }
}
