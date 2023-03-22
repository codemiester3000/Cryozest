import Foundation

enum TherapyType: String, Codable, Identifiable, CaseIterable {
    case drySauna = "Dry Sauna"
    case wetSauna = "Wet Sauna"
    case steamRoom = "Steam Room"
    case infraredSauna = "Infrared Sauna"
    case coldPlunge = "Cold Plunge"
    case coldShower = "Cold Shower"
    
    var id: String { self.rawValue }
}
