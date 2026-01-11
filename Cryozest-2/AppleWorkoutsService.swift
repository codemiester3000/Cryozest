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

            guard let workouts = workouts, let self = self else {
                print("No workouts were found.")
                return
            }

            print("🏃 [APPLE-WORKOUTS] Fetched \(workouts.count) workouts from last 90 days")

            for workout in workouts {
                self.createOrUpdateTherapySessionEntity(from: workout)
            }

            // After saving all workouts, detect recurring patterns and auto-create habits
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let habitDetection = WorkoutHabitDetectionService(context: self.viewContext)
                habitDetection.detectAndCreateHabitsFromWorkouts()
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

                // Fetch and store average heart rate
                fetchAverageHeartRate(for: workout) { avgHR in
                    if let avgHR = avgHR {
                        newSession.averageHeartRate = avgHR
                        try? self.viewContext.save()
                    }
                }
            } else if let existingSession = matches.first {
                // Update existing session if needed
                existingSession.duration = workout.duration

                // Update heart rate if not already set
                if existingSession.averageHeartRate == 0 {
                    fetchAverageHeartRate(for: workout) { avgHR in
                        if let avgHR = avgHR {
                            existingSession.averageHeartRate = avgHR
                            try? self.viewContext.save()
                        }
                    }
                }
            }
            try viewContext.save()
        } catch {
            print("Error fetching or saving: \(error)")
        }
    }

    private func fetchAverageHeartRate(for workout: HKWorkout, completion: @escaping (Double?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
            guard let result = result, let average = result.averageQuantity() else {
                completion(nil)
                return
            }

            let avgHeartRate = average.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async {
                completion(avgHeartRate)
            }
        }

        healthStore.execute(query)
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

// MARK: - Workout Habit Detection

class WorkoutHabitDetectionService {
    private let context: NSManagedObjectContext

    // Detection thresholds
    private let minimumOccurrences = 3  // Need at least 3 workouts
    private let analysisWindowDays = 21  // Look at last 3 weeks

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Analyzes Apple Watch workout patterns and auto-creates habits for recurring workouts
    func detectAndCreateHabitsFromWorkouts() {
        print("🏃 [WORKOUT-HABITS] Starting workout pattern detection...")

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -analysisWindowDays, to: endDate) else {
            print("🏃 [WORKOUT-HABITS] Failed to calculate analysis window")
            return
        }

        // Fetch all Apple Watch workouts from the last 3 weeks
        let workouts = fetchAppleWatchWorkouts(from: startDate, to: endDate)
        print("🏃 [WORKOUT-HABITS] Found \(workouts.count) Apple Watch workouts in last \(analysisWindowDays) days")

        // Group workouts by type
        let workoutsByType = Dictionary(grouping: workouts) { $0.therapyType ?? "" }

        // Detect recurring workout patterns
        var detectedHabits: [TherapyType] = []

        for (therapyTypeString, typeWorkouts) in workoutsByType {
            guard let therapyType = TherapyType(rawValue: therapyTypeString) else { continue }

            // Check if this workout type occurs frequently enough
            if typeWorkouts.count >= minimumOccurrences {
                // Calculate frequency (workouts per week)
                let weeksInPeriod = Double(analysisWindowDays) / 7.0
                let workoutsPerWeek = Double(typeWorkouts.count) / weeksInPeriod

                print("🏃 [WORKOUT-HABITS] \(therapyType.rawValue): \(typeWorkouts.count) workouts (\(String(format: "%.1f", workoutsPerWeek))/week)")

                // If doing this workout 1+ times per week on average, consider it a habit
                if workoutsPerWeek >= 1.0 {
                    detectedHabits.append(therapyType)
                }
            }
        }

        print("🏃 [WORKOUT-HABITS] Detected \(detectedHabits.count) recurring workout habits: \(detectedHabits.map { $0.rawValue })")

        // Get existing selected therapies
        let existingSelectedTherapies = fetchExistingSelectedTherapies()
        let existingTherapyTypes = Set(existingSelectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") })

        // Add new habits that don't already exist
        var newHabitsAdded = 0
        for therapyType in detectedHabits {
            if !existingTherapyTypes.contains(therapyType) {
                createSelectedTherapy(for: therapyType)
                newHabitsAdded += 1
                print("🏃 [WORKOUT-HABITS] ✅ Auto-added habit: \(therapyType.rawValue)")
            } else {
                print("🏃 [WORKOUT-HABITS] ⏭️  Habit already exists: \(therapyType.rawValue)")
            }
        }

        // Save context if we added new habits
        if newHabitsAdded > 0 {
            saveContext()
            print("🏃 [WORKOUT-HABITS] 🎉 Successfully added \(newHabitsAdded) new workout habit(s) to your active habits!")
        } else {
            print("🏃 [WORKOUT-HABITS] No new habits to add")
        }
    }

    // MARK: - Private Helpers

    private func fetchAppleWatchWorkouts(from startDate: Date, to endDate: Date) -> [TherapySessionEntity] {
        let fetchRequest: NSFetchRequest<TherapySessionEntity> = TherapySessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@ AND isAppleWatch == true",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("🏃 [WORKOUT-HABITS] Error fetching workouts: \(error)")
            return []
        }
    }

    private func fetchExistingSelectedTherapies() -> [SelectedTherapy] {
        let fetchRequest: NSFetchRequest<SelectedTherapy> = SelectedTherapy.fetchRequest()

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("🏃 [WORKOUT-HABITS] Error fetching selected therapies: \(error)")
            return []
        }
    }

    private func createSelectedTherapy(for therapyType: TherapyType) {
        let selectedTherapy = SelectedTherapy(context: context)
        selectedTherapy.therapyType = therapyType.rawValue
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("🏃 [WORKOUT-HABITS] Error saving context: \(error)")
        }
    }
}
