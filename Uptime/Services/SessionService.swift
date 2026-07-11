import Foundation
import CoreData

class SessionService {
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func createSession(startTime: Date) -> WorkSession {
        let session = WorkSession(context: viewContext)
        session.id = UUID()
        session.startTime = startTime
        session.date = Calendar.current.startOfDay(for: startTime)
        session.createdAt = Date()
        session.duration = 0
        return session
    }
    
    func endSession(_ session: WorkSession, endTime: Date, elapsed: TimeInterval) {
        session.endTime = endTime
        session.duration = elapsed
        save()
    }
    
    func getSessions(for date: Date) -> [WorkSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        
        let request: NSFetchRequest<WorkSession> = WorkSession.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkSession.startTime, ascending: false)]
        
        return (try? viewContext.fetch(request)) ?? []
    }
    
    func getTotalDuration(for date: Date) -> TimeInterval {
        let sessions = getSessions(for: date)
        return sessions.reduce(0) { $0 + $1.duration }
    }
    
    func getTotalDuration(from startDate: Date, to endDate: Date) -> TimeInterval {
        let sessions = getSessions(from: startDate, to: endDate)
        return sessions.reduce(0) { $0 + ($1.duration > 0 ? $1.duration : 0) }
    }
    
    /// Daily totals keyed by start-of-day, inclusive of both bounds.
    func getDailyDurations(from startDate: Date, to endDate: Date) -> [Date: TimeInterval] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let sessions = getSessions(from: start, to: end)
        
        var daily: [Date: TimeInterval] = [:]
        for session in sessions where session.duration > 0 {
            guard let date = session.date else { continue }
            let day = calendar.startOfDay(for: date)
            daily[day, default: 0] += session.duration
        }
        return daily
    }
    
    func getSessions(from startDate: Date, to endDate: Date) -> [WorkSession] {
        let request: NSFetchRequest<WorkSession> = WorkSession.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkSession.date, ascending: true)]
        
        return (try? viewContext.fetch(request)) ?? []
    }
    
    func hasWorkCompleted(for date: Date) -> Bool {
        return getTotalDuration(for: date) > 0
    }
    
    // Testing methods
    func createTestSession(for date: Date, duration: TimeInterval) {
        let session = WorkSession(context: viewContext)
        session.id = UUID()
        let startTime = Calendar.current.startOfDay(for: date).addingTimeInterval(9 * 3600) // 9 AM
        session.startTime = startTime
        session.endTime = startTime.addingTimeInterval(duration)
        session.date = Calendar.current.startOfDay(for: date)
        session.duration = duration
        session.createdAt = Date()
        save()
    }
    
    func deleteSessions(for date: Date) {
        let sessions = getSessions(for: date)
        sessions.forEach { viewContext.delete($0) }
        save()
    }
    
    func deleteAllSessions() {
        let request: NSFetchRequest<WorkSession> = WorkSession.fetchRequest()
        if let sessions = try? viewContext.fetch(request) {
            sessions.forEach { viewContext.delete($0) }
            save()
        }
    }
    
    private func save() {
        guard viewContext.hasChanges else { return }
        try? viewContext.save()
    }
}

