import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let intensity: Double
    let duration: TimeInterval
    let showsDayNumber: Bool
    /// When set, shown instead of the calendar day-of-month (e.g. day-of-year 1…365).
    var dayNumberOverride: Int? = nil
    let size: CGFloat
    let formatDuration: (TimeInterval) -> String
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    /// Shared with year tiles so month view is a scaled-up version of the same design.
    private static let numberSizeRatio: CGFloat = 0.55
    private static let cornerRadiusRatio: CGFloat = 0.2
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isFuture: Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
    }
    
    private var displayedDayNumber: Int {
        dayNumberOverride ?? calendar.component(.day, from: date)
    }
    
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * Self.cornerRadiusRatio, style: .continuous)
        
        ZStack {
            shape.fill(fillColor)
            
            if showsDayNumber {
                Text("\(displayedDayNumber)")
                    .font(.system(size: size * Self.numberSizeRatio, weight: .medium))
                    .foregroundStyle(dayNumberColor)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                    .padding(.horizontal, 1)
            }
            
            if isToday {
                shape.stroke(Color.white.opacity(0.7), lineWidth: max(1.5, size * 0.06))
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
        .allowsHitTesting(!isFuture)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isFuture ? [] : .isButton)
        .accessibilityAction(named: "Open") { handleTap() }
    }
    
    private func handleTap() {
        guard !isFuture else { return }
        action()
    }
    
    private var fillColor: Color {
        // Future and empty past days share the same gray tile fill
        if isFuture {
            return HeatShade.empty
        }
        return HeatShade.color(for: duration)
    }
    
    private var dayNumberColor: Color {
        if isFuture {
            return .white.opacity(0.35)
        }
        if intensity > 0.45 {
            return .black.opacity(0.85)
        }
        return .white.opacity(0.75)
    }
    
    private var accessibilityLabel: String {
        let day = date.formatted(.dateTime.month().day().weekday(.wide))
        if isFuture {
            return "\(day), upcoming"
        }
        if duration <= 0 {
            return "\(day), no time tracked"
        }
        return "\(day), \(formatDuration(duration))"
    }
}
