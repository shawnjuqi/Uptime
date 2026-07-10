import CoreData
import OSLog

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        return result
    }()

    let container: NSPersistentContainer

    /// Non-nil when the on-disk store failed to load and the app is running
    /// on a temporary in-memory store: sessions from this launch won't persist.
    /// The store file is left on disk untouched so a later launch can recover it.
    private(set) var storeLoadError: NSError?

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Uptime")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        var loadError: NSError?
        container.loadPersistentStores { _, error in
            loadError = error as NSError?
        }

        if let error = loadError {
            Logger(subsystem: "Oriented.Uptime", category: "Persistence")
                .fault("Failed to load persistent store: \(error), \(error.userInfo)")
            storeLoadError = error

            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            container.loadPersistentStores { _, fallbackError in
                if let fallbackError {
                    Logger(subsystem: "Oriented.Uptime", category: "Persistence")
                        .fault("In-memory fallback store also failed: \(fallbackError)")
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
