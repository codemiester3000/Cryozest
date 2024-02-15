import Foundation
import HealthKit
import CoreData

class AppleWorkoutsService {    
    private let healthStore = HKHealthStore()
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    func fetchAndSaveWorkouts() {
        fetchWorkoutsLast90Days { [weak self] (workouts, error) in
            if let error = error {
                print("Error fetching workouts: \(error.localizedDescription)")
                return
            }
            
            guard let workouts = workouts else {
                print("No workouts were found.")
                return
            }
            
            for workout in workouts {
                // Check if the workout is a running workout
                if workout.workoutActivityType == .running {
                    print("Found a running workout: \(workout)")
                }
                self?.createOrUpdateTherapySessionEntity(from: workout)
            }
        }
    }

    
    private func fetchWorkoutsLast90Days(completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let endDate = Date() // Today
        let predicate = HKQuery.predicateForSamples(withStart: ninetyDaysAgo, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            DispatchQueue.main.async {
                guard let workouts = samples as? [HKWorkout] else {
                    completion(nil, error)
                    return
                }
                completion(workouts, nil)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func createOrUpdateTherapySessionEntity(from workout: HKWorkout) {
        let fetchRequest: NSFetchRequest<TherapySessionEntity> = TherapySessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@ AND therapyType == %@", workout.startDate as NSDate, therapyTypeForWorkout(workout).rawValue)
        
        do {
            let matches = try viewContext.fetch(fetchRequest)
            if matches.isEmpty {
                let newSession = TherapySessionEntity(context: viewContext)
                newSession.id = UUID()
                newSession.date = workout.startDate
                newSession.duration = workout.duration
                newSession.isAppleWatch = true
                newSession.therapyType = therapyTypeForWorkout(workout).rawValue
                // Assuming you have a way to fetch average heart rate
                // newSession.averageHeartRate = fetchAverageHeartRate(for: workout)
            } else if let existingSession = matches.first {
                // Update existing session if needed
            }
            try viewContext.save()
        } catch {
            print("Error fetching or saving: \(error)")
        }
    }
    
    private func therapyTypeForWorkout(_ workout: HKWorkout) -> TherapyType {
        // Implement logic to map HKWorkout to your TherapyType
        // This is a simplified example. Adjust according to your actual TherapyType enum.
        switch workout.workoutActivityType {
        case .running: return .running
        case .swimming: return .swimming
        case .cycling: return .cycling
        case .pilates: return .pilates
        case .basketball: return .basketball
        case .elliptical: return .elliptical
        case .hiking: return .hiking
        case .rowing: return .rowing
        case .walking: return .walking
        case .functionalStrengthTraining: return .weightTraining
        case .barre: return .barre
        case .boxing: return .boxing
        case .surfingSports: return .surfing
        case .pickleball: return .pickleball
        case .dance: return .dance
        case .crossTraining: return .crossfit
        case .stairClimbing: return .stairClimbing
            
        // Add more mappings as needed
        default: return .custom1 // or another default value
        }
    }
    
    // Implement fetchAverageHeartRate(for:) if needed
}
