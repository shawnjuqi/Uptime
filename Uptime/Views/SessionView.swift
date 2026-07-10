import SwiftUI

struct SessionView: View {
    let viewModel: SessionViewModel
    
    var body: some View {
        VStack {
            TimerDisplayView(viewModel: viewModel)
            
            SessionControlsView(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct TimerDisplayView: View {
    @Bindable var viewModel: SessionViewModel
    @State private var hoursString = "00"
    @State private var minutesString = "00"
    @State private var secondsString = "00"
    @FocusState private var focusedField: TimeField?
    
    enum TimeField {
        case hours, minutes, seconds
    }
    
    private var isPaused: Bool {
        viewModel.currentSession != nil && !viewModel.isRunning
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isRunning {
                // Show remaining time counting down when running
                Text(formatTime(viewModel.remainingTime))
                    .font(.system(size: 64, design: .monospaced))
                    .bold()
                    .foregroundStyle(.white)
            } else if isPaused {
                // Show paused time when paused
                Text(formatTime(viewModel.remainingTime))
                    .font(.system(size: 64, design: .monospaced))
                    .bold()
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                // Always show editable time fields when not running
                HStack(spacing: 4) {
                    TimeFieldView(
                        text: $hoursString,
                        maxValue: 99,
                        focusedField: $focusedField,
                        field: .hours
                    )
                    
                    Text(":")
                        .font(.system(size: 64, design: .monospaced))
                        .bold()
                        .foregroundStyle(.white)
                    
                    TimeFieldView(
                        text: $minutesString,
                        maxValue: 59,
                        focusedField: $focusedField,
                        field: .minutes
                    )
                    
                    Text(":")
                        .font(.system(size: 64, design: .monospaced))
                        .bold()
                        .foregroundStyle(.white)
                    
                    TimeFieldView(
                        text: $secondsString,
                        maxValue: 59,
                        focusedField: $focusedField,
                        field: .seconds
                    )
                }
                .onChange(of: hoursString) { oldValue, newValue in
                    applyTime()
                }
                .onChange(of: minutesString) { oldValue, newValue in
                    applyTime()
                }
                .onChange(of: secondsString) { oldValue, newValue in
                    applyTime()
                }
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
        .onChange(of: viewModel.isRunning) { oldValue, newValue in
            if newValue {
                focusedField = nil
            } else {
                // When timer stops, update fields from the actual duration
                updateFieldsFromDuration(viewModel.targetDuration)
            }
        }
        .onAppear {
            updateFieldsFromDuration(viewModel.targetDuration)
        }
    }
    
    private func updateFieldsFromDuration(_ duration: TimeInterval) {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        hoursString = String(format: "%02d", hours)
        minutesString = String(format: "%02d", minutes)
        secondsString = String(format: "%02d", seconds)
    }
    
    private func applyTime() {
        let hours = Int(hoursString) ?? 0
        let minutes = Int(minutesString) ?? 0
        let seconds = Int(secondsString) ?? 0
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        if totalSeconds > 0 {
            viewModel.setCustomDuration(hours: hours, minutes: minutes, seconds: seconds)
            viewModel.isTimerEnabled = true
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let hoursString = hours < 10 ? "0\(hours)" : "\(hours)"
        let minutesString = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        return "\(hoursString):\(minutesString):\(secondsString)"
    }
}

struct TimeFieldView: View {
    @Binding var text: String
    let maxValue: Int
    let focusedField: FocusState<TimerDisplayView.TimeField?>.Binding
    let field: TimerDisplayView.TimeField

    var body: some View {
        TextField("00", text: $text)
            .font(.system(size: 64, design: .monospaced))
            .bold()
            .multilineTextAlignment(.center)
            .frame(width: 80, height: 80)
            .focused(focusedField, equals: field)
            .textFieldStyle(.plain)
            .background(Color.clear)
            .foregroundStyle(.white)
            .onChange(of: text) { oldValue, newValue in
                handleInput(newValue)
            }
            .onChange(of: focusedField.wrappedValue) { oldValue, newValue in
                if newValue == field {
                    // When field gains focus, reset to "00"
                    text = "00"
                }
            }
    }
    
    private func handleInput(_ newValue: String) {
        // Extract only digits
        let digits = newValue.filter { $0.isNumber }
        
        if digits.isEmpty {
            text = "00"
            return
        }

        // Right-to-left input: new digits go to the right, old digits shift left
        // Take last 2 digits (rightmost digits)
        let lastTwo = String(digits.suffix(2))

        if let intValue = Int(lastTwo) {
            // Clamp to max value
            let clamped = min(intValue, maxValue)
            text = String(format: "%02d", clamped)
        } else {
            text = "00"
        }
    }
}



struct SessionControlsView: View {
    let viewModel: SessionViewModel
    
    private var isPaused: Bool {
        viewModel.currentSession != nil && !viewModel.isRunning
    }
    
    var body: some View {
        HStack(spacing: 20) {
            if viewModel.isRunning {
                Button {
                    viewModel.pauseSession()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(SessionControlButtonStyle())
            } else if isPaused {
                Button {
                    viewModel.resumeSession()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(SessionControlButtonStyle())
            } else {
                Button {
                    viewModel.startSession()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(SessionControlButtonStyle(emphasized: true))
                .disabled(!viewModel.isTimerEnabled)
            }

            if viewModel.isRunning || isPaused {
                Button {
                    viewModel.stopSession()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(SessionControlButtonStyle())
            }
        }
    }
}

