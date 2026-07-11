import CoreData
@testable import Uptime

/// A throwaway in-memory Core Data stack plus a `SessionService` bound to it,
/// so tests can seed `WorkSession`s without touching the on-disk store.
enum TestStore {
    /// Reuses the model the host app already loaded rather than loading a fresh
    /// one: a second NSManagedObjectModel claiming `WorkSession` makes
    /// `+[WorkSession entity]` ambiguous under the app test host.
    static func makeContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(
            name: "Uptime",
            managedObjectModel: PersistenceController.shared.container.managedObjectModel
        )
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            precondition(error == nil, "in-memory store failed: \(String(describing: error))")
        }
        return container.viewContext
    }

    /// Seeds one session per (day-offset, hours) pair, relative to the start of
    /// today, and returns the service/context so callers can build view models.
    static func seed(_ dayOffsetsHours: [(daysAgo: Int, hours: Double)])
        -> (service: SessionService, context: NSManagedObjectContext) {
        let context = makeContext()
        let service = SessionService(viewContext: context)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for entry in dayOffsetsHours {
            guard let day = calendar.date(byAdding: .day, value: -entry.daysAgo, to: today) else { continue }
            service.createTestSession(for: day, duration: entry.hours * 3600)
        }
        return (service, context)
    }
}
