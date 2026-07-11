import SwiftUI

struct StatsDayBarColumn: View {
    let day: StatsDayTotal
    let maxDuration: TimeInterval
    let formatDuration: (TimeInterval) -> String
    
    @State private var isHovered = false
    
    private let barMaxHeight: CGFloat = 56
    private let barMinHeight: CGFloat = 4
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    private var hasTime: Bool {
        day.duration >= 60
    }
    
    private var barHeight: CGFloat {
        if day.duration <= 0 {
            return barMinHeight
        }
        let ratio = day.duration / maxDuration
        return max(barMinHeight, CGFloat(ratio) * barMaxHeight)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(valueLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: 14)
            
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(barColor)
                .frame(maxWidth: 36)
                .frame(height: barHeight)
                .frame(maxWidth: .infinity)
            
            Text(dayLabel)
                .font(.system(size: 11, weight: isToday ? .semibold : .regular))
                .foregroundStyle(isToday ? .white : .white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.06 : 0))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var valueLabel: String {
        if hasTime || isHovered {
            return formatDuration(day.duration)
        }
        return " "
    }
    
    private var valueColor: Color {
        if hasTime {
            return .white.opacity(0.9)
        }
        return isHovered ? .white.opacity(0.55) : .clear
    }
    
    private var barColor: Color {
        if day.duration > 0 {
            return .white.opacity(isToday ? 0.95 : 0.75)
        }
        return .white.opacity(0.18)
    }
    
    private var dayLabel: String {
        if isToday {
            return "Today"
        }
        return day.date.formatted(.dateTime.weekday(.narrow))
    }
    
    private var accessibilityLabel: String {
        let name = isToday ? "Today" : day.date.formatted(.dateTime.weekday(.wide))
        return "\(name), \(formatDuration(day.duration))"
    }
}
