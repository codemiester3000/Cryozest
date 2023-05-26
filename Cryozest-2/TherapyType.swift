import Foundation

enum TherapyType: String, Codable, Identifiable, CaseIterable {
    case drySauna = "Sauna"
    case hotYoga = "Hot Yoga"
    case coldPlunge = "Cold Plunge"
    case coldShower = "Cold Shower"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .drySauna:
            return "flame.fill" // Suggests heat
        case .hotYoga:
            return "leaf.fill" // Suggests steam
        case .coldPlunge:
            return "thermometer.snowflake" // Suggests cold water
        case .coldShower:
            return "drop.fill" // Suggests a shower
        }
    }
}
