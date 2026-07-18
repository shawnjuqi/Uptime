import SwiftUI

struct SessionView: View {
    let viewModel: SessionViewModel
    @FocusState private var isEntryFocused: Bool

    var body: some View {
        VStack {
            TimerDisplayView(viewModel: viewModel, isEntryFocused: $isEntryFocused)

            SessionControlsView(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .contentShape(Rectangle())
        .onTapGesture {
            // Clicking empty space drops focus, which also clears any
            // segment selection via TimerDisplayView's focus observer
            isEntryFocused = false
        }
    }
}

struct TimerDisplayView: View {
    @Bindable var viewModel: SessionViewModel
    var isEntryFocused: FocusState<Bool>.Binding

    @State private var hours = 0
    @State private var minutes = 0
    @State private var seconds = 0
    @State private var selectedSegment: TimeSegment?
    @State private var hoveredSegment: TimeSegment?
    @State private var segmentBuffer = ""

    enum TimeSegment {
        case hours, minutes, seconds
    }

    private var isPaused: Bool {
        viewModel.currentSession != nil && !viewModel.isRunning
    }

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isRunning {
                staticTimeView(viewModel.remainingTime, color: .white)
            } else if isPaused {
                staticTimeView(viewModel.remainingTime, color: .white.opacity(0.6))
            } else {
                digitEntryView
            }

            if viewModel.isTimerEnabled && (viewModel.isRunning || isPaused) {
                if viewModel.isTimerComplete {
                    Text("Timer Complete!")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !viewModel.isRunning && !isPaused else { return }
            selectedSegment = nil
            segmentBuffer = ""
            isEntryFocused.wrappedValue = true
        }
        .onChange(of: isEntryFocused.wrappedValue) { oldValue, newValue in
            if !newValue {
                selectedSegment = nil
                segmentBuffer = ""
            }
        }
        .onChange(of: viewModel.isRunning) { oldValue, newValue in
            if newValue {
                selectedSegment = nil
                segmentBuffer = ""
            } else {
                setTime(from: viewModel.targetDuration)
            }
        }
        .onAppear {
            setTime(from: viewModel.targetDuration)
        }
    }

    // MARK: - Display

    // Entry is per-segment: click an hr/min/sec pair to select it, then
    // type (clamped to the unit's cap) or nudge with the arrow keys
    private var digitEntryView: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            segmentView(.hours, label: "hr")
            colonView(.white)
            segmentView(.minutes, label: "min")
            colonView(.white)
            segmentView(.seconds, label: "sec")
        }
        .focusable()
        .focused(isEntryFocused)
        .focusEffectDisabled()
        .onKeyPress(phases: [.down, .repeat]) { press in
            handleKey(press)
        }
        .onAppear {
            isEntryFocused.wrappedValue = true
        }
    }

    private func colonView(_ color: Color) -> some View {
        Text(":")
            .font(.system(size: 64, design: .monospaced))
            .bold()
            .foregroundStyle(color)
    }

    private func segmentView(_ segment: TimeSegment, label: String) -> some View {
        let isSelected = selectedSegment == segment
        let isHovered = hoveredSegment == segment
        return VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            Text(segmentDigits(for: segment))
                .font(.system(size: 64, design: .monospaced))
                .bold()
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(isSelected ? 0.2 : (isHovered ? 0.08 : 0)))
                )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedSegment = isSelected ? nil : segment
            segmentBuffer = ""
            isEntryFocused.wrappedValue = true
        }
        .onHover { hovering in
            if hovering {
                hoveredSegment = segment
                NSCursor.pointingHand.push()
            } else {
                if hoveredSegment == segment {
                    hoveredSegment = nil
                }
                NSCursor.pop()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityName(for: segment))
        .accessibilityValue("\(value(of: segment))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: nudge(segment, by: 1)
            case .decrement: nudge(segment, by: -1)
            @unknown default: break
            }
        }
    }

    private func staticTimeView(_ timeInterval: TimeInterval, color: Color) -> some View {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return HStack(alignment: .lastTextBaseline, spacing: 4) {
            staticSegmentView(String(format: "%02d", hours), label: "hr", color: color)
            colonView(color)
            staticSegmentView(String(format: "%02d", minutes), label: "min", color: color)
            colonView(color)
            staticSegmentView(String(format: "%02d", seconds), label: "sec", color: color)
        }
    }

    // Mirrors segmentView's layout so the display doesn't shift between
    // entry, running, and paused states
    private func staticSegmentView(_ digits: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
            Text(digits)
                .font(.system(size: 64, design: .monospaced))
                .bold()
                .foregroundStyle(color)
                .padding(.horizontal, 4)
        }
    }

    // Leading zeros render dim; everything from the first significant digit
    // on is bright (trailing zeros are significant)
    private func segmentDigits(for segment: TimeSegment) -> AttributedString {
        let digits = Array(composedDigits)
        let firstSignificant = digits.firstIndex(where: { $0 != "0" }) ?? digits.count
        let isSelected = selectedSegment == segment

        var result = AttributedString()
        for index in digitRange(for: segment) {
            var piece = AttributedString(String(digits[index]))
            piece.foregroundColor = (isSelected || index >= firstSignificant) ? .white : .white.opacity(0.3)
            result += piece
        }
        return result
    }

    private var composedDigits: String {
        String(format: "%02d%02d%02d", hours, minutes, seconds)
    }

    private func digitRange(for segment: TimeSegment) -> Range<Int> {
        switch segment {
        case .hours: return 0..<2
        case .minutes: return 2..<4
        case .seconds: return 4..<6
        }
    }

    private func accessibilityName(for segment: TimeSegment) -> String {
        switch segment {
        case .hours: return "hours"
        case .minutes: return "minutes"
        case .seconds: return "seconds"
        }
    }

    // MARK: - Key handling

    // Backspace arrives inconsistently across systems (.delete, .deleteForward,
    // or only as a raw control character), so match every representation
    private func isDeletePress(_ press: KeyPress) -> Bool {
        press.key == .delete || press.key == .deleteForward
            || press.characters == "\u{7F}" || press.characters == "\u{08}"
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        if let segment = selectedSegment {
            return handleSegmentKey(press, for: segment)
        }

        switch press.key {
        case .return:
            guard viewModel.isTimerEnabled else { return .ignored }
            viewModel.startSession()
            return .handled
        case .rightArrow:
            selectedSegment = .hours
            return .handled
        case .leftArrow:
            selectedSegment = .seconds
            return .handled
        default:
            return .ignored
        }
    }

    private func handleSegmentKey(_ press: KeyPress, for segment: TimeSegment) -> KeyPress.Result {
        if isDeletePress(press) {
            setValue(0, for: segment)
            segmentBuffer = ""
            return .handled
        }

        switch press.key {
        case .upArrow:
            nudge(segment, by: 1)
            return .handled
        case .downArrow:
            nudge(segment, by: -1)
            return .handled
        case .leftArrow:
            if let previous = previousSegment(before: segment) {
                selectedSegment = previous
                segmentBuffer = ""
            }
            return .handled
        case .rightArrow:
            if let next = nextSegment(after: segment) {
                selectedSegment = next
                segmentBuffer = ""
            }
            return .handled
        case .escape:
            selectedSegment = nil
            segmentBuffer = ""
            return .handled
        case .return:
            guard viewModel.isTimerEnabled else { return .ignored }
            selectedSegment = nil
            viewModel.startSession()
            return .handled
        default:
            guard let digit = press.characters.first, digit.isNumber else { return .ignored }
            segmentBuffer = String((segmentBuffer + String(digit)).suffix(2))
            let clamped = min(Int(segmentBuffer) ?? 0, cap(for: segment))
            setValue(clamped, for: segment)
            return .handled
        }
    }

    // MARK: - Segment values

    private func cap(for segment: TimeSegment) -> Int {
        segment == .hours ? 23 : 59
    }

    private func value(of segment: TimeSegment) -> Int {
        switch segment {
        case .hours: return hours
        case .minutes: return minutes
        case .seconds: return seconds
        }
    }

    private func setValue(_ newValue: Int, for segment: TimeSegment) {
        switch segment {
        case .hours: hours = newValue
        case .minutes: minutes = newValue
        case .seconds: seconds = newValue
        }
        applyTime()
    }

    private func nudge(_ segment: TimeSegment, by delta: Int) {
        let cap = cap(for: segment)
        let current = min(value(of: segment), cap)
        let wrapped = (current + delta + cap + 1) % (cap + 1)
        setValue(wrapped, for: segment)
        segmentBuffer = ""
    }

    private func nextSegment(after segment: TimeSegment) -> TimeSegment? {
        switch segment {
        case .hours: return .minutes
        case .minutes: return .seconds
        case .seconds: return nil
        }
    }

    private func previousSegment(before segment: TimeSegment) -> TimeSegment? {
        switch segment {
        case .hours: return nil
        case .minutes: return .hours
        case .seconds: return .minutes
        }
    }

    private func applyTime() {
        if hours == 0 && minutes == 0 && seconds == 0 {
            viewModel.resetTimer()
        } else {
            viewModel.setCustomDuration(hours: hours, minutes: minutes, seconds: seconds)
        }
    }

    private func setTime(from duration: TimeInterval) {
        let totalSeconds = Int(duration)
        hours = min(totalSeconds / 3600, 23)
        minutes = (totalSeconds % 3600) / 60
        seconds = totalSeconds % 60
        applyTime()
    }
}

struct SessionControlsView: View {
    let viewModel: SessionViewModel

    private var isPaused: Bool {
        viewModel.currentSession != nil && !viewModel.isRunning
    }

    var body: some View {
        HStack(spacing: 20) {
            if viewModel.isCompleted {
                // Intentionally empty: a finished timer has no primary action, only Stop.
                EmptyView()
            } else if viewModel.isRunning {
                Button {
                    viewModel.pauseSession()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(PillButtonStyle(width: 120))
            } else if isPaused {
                Button {
                    viewModel.resumeSession()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(PillButtonStyle(width: 120))
            } else {
                Button {
                    viewModel.startSession()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(PillButtonStyle(width: 120))
                .disabled(!viewModel.isTimerEnabled)
            }

            if viewModel.isRunning || isPaused {
                Button {
                    viewModel.stopSession()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(PillButtonStyle(width: 120))
            }
        }
    }
}
