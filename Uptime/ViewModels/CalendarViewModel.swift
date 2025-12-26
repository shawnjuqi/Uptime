import Foundation
import CoreData
import Observation

@MainActor
@Observable
final class CalendarViewModel {
    var selectedDate = Date()
    var workDays: Set<Date> = []
    
    private let sessionService: SessionService
    private let calendar = Calendar.current
    
    init(viewContext: NSManagedObjectContext) {
        self.sessionService = SessionService(viewContext: viewContext)
        loadWorkDays()
    }
    
    func loadWorkDays(for year: Date? = nil) {
        let targetDate = year ?? Date()
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: targetDate)),
              let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
            return
        }
        
        let sessions = sessionService.getSessions(from: startOfYear, to: endOfYear)
        workDays = Set(sessions.compactMap { $0.date })
        
        // Update shared storage for widget
        SharedStorage.saveWorkDays(Array(workDays))
    }
    
    func hasWorkCompleted(for date: Date) -> Bool {
        return workDays.contains(calendar.startOfDay(for: date))
    }
    
    func refresh(for year: Date? = nil) {
        loadWorkDays(for: year)
    }
}

