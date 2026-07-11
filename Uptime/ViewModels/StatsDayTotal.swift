import Foundation

struct StatsDayTotal: Identifiable {
    let date: Date
    let duration: TimeInterval
    
    var id: Date { date }
}
