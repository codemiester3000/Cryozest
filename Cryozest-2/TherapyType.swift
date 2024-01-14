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
    case magnesium = "Magnesium"
    case zinc = "Zinc"
    case d3 = "D3"
    // Diet
    case noCoffee = "No Coffee"
    case noCaffeine = "No Caffeine"
    case vegetarian = "Vegetarian Diet"
    case vegan = "Vegan Diet"
    case keto = "Keto Diet"
    case noSugar = "No sugar"
    case custom1 = "Custom 1"
    case custom2 = "Custom 2"
    case custom3 = "Custom 3"
    case custom4 = "Custom 4"
    case custom5 = "Custom 5"
    case custom6 = "Custom 6"
    case custom7 = "Custom 7"
    case custom8 = "Custom 8"
    
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
        case .magnesium, .zinc, .d3:
            return "capsule"
        case .noCoffee, .noSugar, .noCaffeine, .vegan, .vegetarian, .keto:
            return "cup.and.saucer.fill"
        case .custom1:
            return "person.fill"
        case .custom2:
            return "person.fill"
        case .custom3:
            return "person.fill"
        case .custom4:
            return "person.fill"
        case .custom5:
            return "person.fill"
        case .custom6:
            return "person.fill"
        case .custom7:
            return "person.fill"
        case .custom8:
            return "person.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .drySauna, .hotYoga:
            return Color.orange
        case .coldPlunge, .coldShower, .iceBath:
            return Color.blue
        case .running, .weightTraining:
            return Color.red
        case .meditation, .stretching, .deepBreathing, .sleep, .coldYoga:
            return Color(red: 0.0, green: 0.5, blue: 0.0)
        case .custom1, .custom2, .custom3, .custom4, .custom5, .custom6, .custom7, .custom8:
            return Color.purple
        case .magnesium, .zinc, .d3:
            return Color.teal
        case .noCoffee, .noCaffeine, .vegan, .vegetarian, .keto, .noSugar:
            return Color.mint
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
        case .custom5:
            return 5
        case .custom6:
            return 6
        case .custom7:
            return 7
        case .custom8:
            return 8
        default:
            return 0 // Or handle other cases as needed
        }
    }
    
    static func therapies(forCategory category: Category) -> [TherapyType] {
        switch category {
        case .category0:
            return TherapyType.allCases
        case .category1: // Heat-Based
            return [.drySauna, .hotYoga]
        case .category2: // Cold-Based
            return [.coldPlunge, .coldShower, .iceBath]
        case .category3:
            return [.meditation, .deepBreathing, .sleep, .coldYoga, .stretching]
        case .category4: // Workouts
            return [.running, .weightTraining]
        case .category5:
            return [.magnesium, .zinc, .d3]
        case .category6: // Diet
            return [.noCoffee, .noSugar, .noCaffeine, .keto, .vegetarian, .vegan]
        case .category7: // Custom
            return [.custom1, .custom2, .custom3, .custom4, .custom5, .custom6, .custom7, .custom8]
        }
    }
}

enum Category: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    case category0 = "All"
    case category1 = "Heat-Based"
    case category2 = "Cold-Based"
    case category3 = "Recovery"
    case category4 = "Workouts"
    case category5 = "Supplements"
    case category6 = "Diet"
    case category7 = "Custom"
}
