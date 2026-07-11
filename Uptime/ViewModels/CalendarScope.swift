import Foundation

enum CalendarScope: String, CaseIterable, Identifiable {
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: "Month"
        case .year: "Year"
        }
    }
}
