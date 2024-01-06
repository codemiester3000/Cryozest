import SwiftUI
import CoreData

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
    case custom1 = "Custom 1"
    case custom2 = "Custom 2"
    case custom3 = "Custom 3"
    case custom4 = "Custom 4"
    
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
        case .custom1:
            return "person.fill"
        case .custom2:
            return "person.fill"
        case .custom3:
            return "person.fill"
        case .custom4:
            return "person.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .drySauna, .hotYoga, .running, .weightTraining:
            return Color.orange
        case .coldPlunge, .coldShower, .iceBath, .coldYoga:
            return Color.blue
        case .meditation, .stretching, .deepBreathing, .sleep:
            return Color(red: 0.0, green: 0.5, blue: 0.0)
        case .custom1, .custom2, .custom3, .custom4:
            return Color.purple
        }
    }
    
    func displayName(_ managedObjectContext: NSManagedObjectContext) -> String {
        switch self {
        case .custom1, .custom2, .custom3, .custom4:
            let therapyID = therapyTypeToID()
            let fetchRequest: NSFetchRequest<CustomTherapy> = CustomTherapy.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %d", therapyID)
            
            do {
                let results = try managedObjectContext.fetch(fetchRequest)
                if let customTherapy = results.first, let customName = customTherapy.name, !customName.isEmpty {
                    return customName
                }
            } catch {
                // Handle or log error
                print("Error fetching custom therapy: \(error)")
            }
            return self.rawValue
        default:
            return self.rawValue
        }
    }
    
    func therapyTypeToID() -> Int16 {
        switch self {
        case .custom1:
            return 1
        case .custom2:
            return 2
        case .custom3:
            return 3
        case .custom4:
            return 4
        default:
            return 0 // Or handle other cases as needed
        }
    }
}

