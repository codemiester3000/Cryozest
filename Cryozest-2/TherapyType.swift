import Foundation

enum TherapyType: String, Codable, Identifiable, CaseIterable {
    case drySauna = "Sauna"
    case steamRoom = "Steam Room"
    case coldPlunge = "Cold Plunge"
    case coldShower = "Cold Shower"
    
    var id: String { self.rawValue }
}
