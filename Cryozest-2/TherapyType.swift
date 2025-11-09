import SwiftUI
import CoreData

enum TherapyType: String, Codable, Identifiable, CaseIterable {
    // Apple-Watch Workouts
//    case appleAmericanFootball = "American Football"
//    case appleArchery = "Archery"
//    case appleAustralianFootball = "Australian Football"
//    case appleBadminton = "Badminton"
//    case appleBarre = "Barre"
//    case appleBaseball = "Baseball"
//    case appleBasketball = "Basketball"
//    case appleBowling = "Bowling"
//    case appleBoxing = "Boxing" // Traditional boxing, not fitness or shadow boxing
//    case appleClimbing = "Climbing"
//    case appleCricket = "Cricket"
//    case appleCrossCountrySkiing = "Cross Country Skiing"
//    case appleCrossTraining = "Cross Training" // Used when none of the other types apply
//    case appleCurling = "Curling"
//    case appleCycling = "Cycling"
//    case appleDance = "Dance"
//    case appleDanceInspiredTraining = "Dance Inspired Training"
//    case appleDownhillSkiing = "Downhill Skiing"
//    case appleElliptical = "Elliptical"
//    case appleEquestrianSports = "Equestrian Sports" // Riding, jumping
//    case appleFencing = "Fencing"
//    case appleFishing = "Fishing"
//    case appleFunctionalStrengthTraining = "Functional Strength Training"
//    case appleGolf = "Golf"
//    case appleGymnastics = "Gymnastics"
//    case appleHandball = "Handball"
//    case appleHiking = "Hiking"
//    case appleHockey = "Hockey"
//    case appleHunting = "Hunting"
//    case appleIceSkating = "Ice Skating"
//    case appleJumpRope = "Jump Rope"
//    case appleKickboxing = "Kickboxing"
//    case appleLacrosse = "Lacrosse"
//    case appleMartialArts = "Martial Arts"
//    case appleMindAndBody = "Mind And Body" // Yoga, tai chi, and similar
//    case appleMixedCardio = "Mixed Cardio" // Any mix of cardio workout types
//    case applePaddleSports = "Paddle Sports"
//    case applePilates = "Pilates"
//    case applePlay = "Play" // Physical activity without a specific fitness goal, such as playing with kids
//    case applePreparationAndRecovery = "Preparation And Recovery"
//    case appleRacquetball = "Racquetball"
//    case appleRowing = "Rowing"
//    case appleRugby = "Rugby"
//    case appleRunning = "Running"
//    case appleSailing = "Sailing"
//    case appleSkatingSports = "Skating Sports" // Ice skating, speed skating, figure skating
//    case appleSnowboarding = "Snowboarding"
//    case appleSnowSports = "Snow Sports" // Skiing, snowboarding, and other snow sports
//    case appleSoccer = "Soccer"
//    case appleSoftball = "Softball"
//    case appleSquash = "Squash"
//    case appleStairClimbing = "Stair Climbing" // Machine-based or actual stairs
//    case appleSurfingSports = "Surfing Sports" // Surfing, bodyboarding, paddleboarding
//    case appleSwimming = "Swimming"
//    case appleTableTennis = "Table Tennis"
//    case appleTaiChi = "Tai Chi"
//    case appleTennis = "Tennis"
//    case appleTrackAndField = "Track And Field" // Discus, javelin, shot put, steeplechase, etc.
//    case appleTraditionalStrengthTraining = "Traditional Strength Training"
//    case appleVolleyball = "Volleyball"
//    case appleWalking = "Walking"
//    case appleWaterFitness = "Water Fitness"
//    case appleWaterPolo = "Water Polo"
//    case appleWaterSports = "Water Sports" // Water skiing, wakeboarding
//    case appleWrestling = "Wrestling"
//    case appleYoga = "Yoga"
    
    // Hot-Based (COMMENTED OUT FOR APP STORE COMPLIANCE - DO NOT SUGGEST EXTREME TEMPERATURE ACTIVITIES)
    // case drySauna = "Sauna"
    // case hotYoga = "Hot Yoga"

    // Cold-Based (COMMENTED OUT FOR APP STORE COMPLIANCE - DO NOT SUGGEST EXTREME TEMPERATURE ACTIVITIES)
    // case coldPlunge = "Cold Plunge"
    // case coldShower = "Cold Shower"
    // case iceBath = "Ice Bath"
    
    // Workouts
    case running = "Running"
    case cycling = "Cycling"
    case pilates = "Pilates"
    case basketball = "Basketball"
    case elliptical = "Elliptical"
    case swimming = "Swimming"
    case hiking = "Hiking"
    case rowing = "Rowing"
    case walking = "Walking"
    case weightTraining = "Lifting"
    case barre = "Barre"
    case rockClimbing = "Rock Climbing"
    case surfing = "Surfing"
    case pickleball = "Pickleball"
    case boxing = "Boxing"
    case crossfit = "CrossFit"
    case dance = "Dance"
    case stairClimbing = "StairClimbing"
    
    // Recovery
    case coldYoga = "Yoga"
    case meditation = "Meditation"
    case stretching = "Stretching"
    case deepBreathing = "Deep Breathing"
    case sleep = "Sleep"
    case massage = "Massage"
    case nap = "Nap"
    case sleepAid = "Sleep Aid"
    case sleepMask = "Sleep Mask"
    case whiteNoise = "White Noise"
    
    // Supplements
    case magnesium = "Magnesium"
    case zinc = "Zinc"
    case d3 = "D3"
    case adaptogens = "Adaptogens"
    case antidepressant = "Antidepressant"
    case creatine = "Creatine"
    case iron = "Iron"
    case lTheanine = "L-Theanine"
    case multivitamin = "Multivitamin"
    case vitaminC = "Vitamin C"
    case cbd = "CBD"
    case electrolytes = "Electrolytes"
    case fishOil = "Fish Oil"
    case ashwagandha = "Ashwagandha"
    case melatonin = "Melatonin"
    
    // Diet
    case noCoffee = "No Coffee"
    case noCaffeine = "No Caffeine"
    case vegetarian = "Vegetarian Diet"
    case vegan = "Vegan Diet"
    case keto = "Keto Diet"
    case noSugar = "No sugar"
    case Dairy = "Dairy"
    case Fasting = "Fasting"
    case Gluten = "Gluten"
    case HighCarb = "High Carb"
    case JunkFood = "Junk Food"
    case LateMeal = "Late Meal"
    case Sugar = "Sugar"
    
    // Other
    case allergies = "Allergies"
    case animalInBed = "Animal in Bed"
    case artificialLight = "Artificial Light"
    case badWeather = "Bad Weather"
    case blueLightBlocker = "Blue Light Blocker"
    case childCare = "Child Care"
    case earPlugs = "Ear Plugs"
    case familyTime = "Family Time"
    case fatigue = "Fatigue"
    case friendTime = "Friend Time"
    case hydration = "Hydration"
    case injury = "Injury"
    case jobStress = "Job Stress"
    case lifeStress = "Life Stress"
    case medication = "Medication"
    case menstruation = "Menstruation"
    case microdosing = "Microdosing"
    case migraine = "Migraine"
    case nightmares = "Nightmares"
    case office = "Office"
    case ovulating = "Ovulating"
    case pms = "PMS"
    case pregnancy = "Pregnancy"
    case reading = "Reading"
    case remoteWork = "Remote Work"
    case sexualActivity = "Sexual Activity"
    case sharedBed = "Shared Bed"
    case shiftWork = "Shift Work"
    case sickness = "Sickness"
    case snoring = "Snoring"
    case stimulantMedication = "Stimulant Medication"
    case sunlight = "Sunlight"
    case thc = "THC"
    case tobacco = "Tobacco"
    case travel = "Travel"
    case vacation = "Vacation"
    case vaccination = "Vaccination"
    case vividDreams = "Vivid Dreams"
    case workingLate = "Working Late"
    
    
    // Custom
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
        // COMMENTED OUT FOR APP STORE COMPLIANCE
        // case .drySauna:
        //     return "flame.fill"
        // case .hotYoga:
        //     return "bolt.fill"
        case .walking, .running, .stairClimbing, .pickleball, .basketball, .elliptical, .barre:
            return "figure.walk"
        case .weightTraining:
            return "dumbbell.fill"
        // COMMENTED OUT FOR APP STORE COMPLIANCE
        // case .coldPlunge:
        //     return "snow"
        // case .coldShower:
        //     return "drop.fill"
        // case .iceBath:
        //     return "snowflake"
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
        case .magnesium, .zinc, .d3, .adaptogens, .antidepressant, .creatine, .iron, .lTheanine, .multivitamin, .vitaminC, .cbd, .electrolytes, .fishOil, .ashwagandha, .melatonin:
            return "capsule"
        case .noCoffee, .noSugar, .noCaffeine, .vegan, .vegetarian, .keto, .Dairy, .Fasting, .Gluten, .HighCarb, .JunkFood, .LateMeal, .Sugar:
            return "cup.and.saucer.fill"
        case .custom1:
            return "person.fill"
        case .custom2:
            return "person.fill"
        case .custom3:
            return "person.fill"
        case .custom4, .custom5, .custom6, .custom7, .custom8:
            return "person.fill"
            // Recovery items
        case .massage:
            return "person.crop.rectangle"
        case .nap:
            return "bed.double.fill"
        case .sleepAid:
            return "pills.fill"
        case .sleepMask:
            return "moon.stars.fill"
        case .whiteNoise:
            return "waveform.path.ecg"
            
            // 'Other' category
        case .allergies, .animalInBed, .artificialLight, .badWeather, .blueLightBlocker,
                .childCare, .earPlugs, .familyTime, .fatigue, .friendTime, .hydration,
                .injury, .jobStress, .lifeStress, .medication, .menstruation, .microdosing,
                .migraine, .nightmares, .office, .ovulating, .pms, .pregnancy, .reading,
                .remoteWork, .sexualActivity, .sharedBed, .shiftWork, .sickness, .snoring,
                .stimulantMedication, .sunlight, .thc, .tobacco, .travel, .vacation,
                .vaccination, .vividDreams, .workingLate:
            return "tray.fill"
            
            // Icons for new workouts
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.wave"
        case .boxing:
            return "bolt.fill"
        case .pilates:
            return "person.2.fill"
        case .crossfit:
            return "bolt.heart.fill"
        case .dance:
            return "music.note.list"
        case .rockClimbing:
            return "figure.climbing"
        case .hiking:
            return "map.fill"
        case .rowing:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .surfing:
            return "wave.3.right"
        default:
            return ""
        }
    }
    
    
    var color: Color {
        switch self {
        // COMMENTED OUT FOR APP STORE COMPLIANCE
        // case .drySauna, .hotYoga:
        //     return Color.orange
        // case .coldPlunge, .coldShower, .iceBath:
        //     return Color.blue
        case .running, .weightTraining, .cycling, .swimming, .boxing, .pilates, .crossfit, .dance, .rockClimbing, .hiking, .rowing, .surfing, .pickleball, .basketball, .elliptical, .barre, .walking, .stairClimbing:
            return Color.appleLimeGreen
        case .meditation, .stretching, .deepBreathing, .sleep, .coldYoga, .massage, .nap, .sleepAid, .sleepMask, .whiteNoise:
            return Color.appleLimeGreen
        case .magnesium, .zinc, .d3, .adaptogens, .antidepressant, .creatine, .iron, .lTheanine, .multivitamin, .vitaminC, .cbd, .electrolytes, .fishOil, .ashwagandha, .melatonin:
            return Color.teal
        case .noCoffee, .noCaffeine, .vegan, .vegetarian, .keto, .noSugar, .Dairy, .Fasting, .Gluten, .HighCarb, .JunkFood, .LateMeal, .Sugar:
            return Color.mint
        case .allergies, .animalInBed, .artificialLight, .badWeather, .blueLightBlocker, .childCare, .earPlugs, .familyTime, .fatigue, .friendTime, .hydration, .injury, .jobStress, .lifeStress, .medication, .menstruation, .microdosing, .migraine, .nightmares, .office, .ovulating, .pms, .pregnancy, .reading, .remoteWork, .sexualActivity, .sharedBed, .shiftWork, .sickness, .snoring, .stimulantMedication, .sunlight, .thc, .tobacco, .travel, .vacation, .vaccination, .vividDreams, .workingLate:
            return Color.indigo
            
        case .custom1, .custom2, .custom3, .custom4, .custom5, .custom6, .custom7, .custom8:
            return Color.purple
            
        default:
            return Color.gray
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
        case .category0: // Workouts
            return [.running, .walking, .stairClimbing, .weightTraining, .cycling, .swimming, .boxing, .pilates, .crossfit, .dance, .rockClimbing, .hiking, .rowing, .surfing, .pickleball, .basketball, .elliptical, .barre]
        case .category1: // All
            return TherapyType.allCases
        // COMMENTED OUT FOR APP STORE COMPLIANCE - DO NOT SUGGEST EXTREME TEMPERATURE ACTIVITIES
        // case .category2: // Heat-Based
        //     return [.drySauna, .hotYoga]
        // case .category3: // Cold-Based
        //     return [.coldPlunge, .coldShower, .iceBath]
        case .category4: // Recovery
            return [.meditation, .deepBreathing, .sleep, .coldYoga, .stretching, .massage, .nap, .sleepAid, .sleepMask, .whiteNoise]
        case .category5: // Supplements
            return [.magnesium, .zinc, .d3, .adaptogens, .antidepressant, .creatine, .iron, .lTheanine, .multivitamin, .vitaminC, .cbd, .electrolytes, .fishOil, .ashwagandha, .melatonin]
        case .category6: // Diet
            return [.noCoffee, .noSugar, .noCaffeine, .keto, .vegetarian, .vegan, .Dairy, .Fasting, .Gluten, .HighCarb, .JunkFood, .LateMeal, .Sugar]
        case .category8: // Other
            return [
                .allergies, .animalInBed, .artificialLight, .badWeather, .blueLightBlocker, .childCare, .earPlugs, .familyTime, .fatigue, .friendTime, .hydration, .injury, .jobStress, .lifeStress, .medication, .menstruation, .microdosing, .migraine, .nightmares, .office, .ovulating, .pms, .pregnancy, .reading, .remoteWork, .sexualActivity, .sharedBed, .shiftWork, .sickness, .snoring, .stimulantMedication, .sunlight, .thc, .tobacco, .travel, .vacation, .vaccination, .vividDreams, .workingLate]
        case .category7: // Custom
            return [.custom1, .custom2, .custom3, .custom4, .custom5, .custom6, .custom7, .custom8]
        }
    }
}


enum Category: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case category0 = "Workouts"
    case category1 = "All"
    // COMMENTED OUT FOR APP STORE COMPLIANCE - DO NOT SUGGEST EXTREME TEMPERATURE ACTIVITIES
    // case category2 = "Heat-Based"
    // case category3 = "Cold-Based"
    case category4 = "Recovery"
    case category5 = "Supplements"
    case category6 = "Diet"
    case category7 = "Custom"
    case category8 = "Other"
}
