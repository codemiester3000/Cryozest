import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Add preview data here if necessary
        let previewSession = TherapySessionEntity(context: viewContext)
        previewSession.date = "03/26/2023"
        previewSession.duration = 1800
        previewSession.temperature = 180
        previewSession.therapyType = "Dry Sauna"
        previewSession.id = UUID()

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Error: \(nsError), \(nsError.userInfo)")
        }

        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CryozestModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
}

