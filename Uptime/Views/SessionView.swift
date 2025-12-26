import SwiftUI

struct SessionView: View {
    let viewModel: SessionViewModel
    
    var body: some View {
        VStack {
            TimerDisplayView(viewModel: viewModel)
            
            SessionControlsView(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                Text(formatTime(viewModel.remainingTime > 0 ? viewModel.remainingTime : 0))
                    .font(.system(size: 64, design: .monospaced))
                    .bold()
                    .foregroundStyle(viewModel.isTimerComplete ? .green : .primary)
            } else if isPaused {
                // Show paused time when paused
                Text(formatTime(viewModel.remainingTime > 0 ? viewModel.remainingTime : 0))
                    .font(.system(size: 64, design: .monospaced))
                    .bold()
                    .foregroundStyle(.secondary)
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
                    
                    TimeFieldView(
                        text: $minutesString,
                        maxValue: 59,
                        focusedField: $focusedField,
                        field: .minutes
                    )
                    
                    Text(":")
                        .font(.system(size: 64, design: .monospaced))
                        .bold()
                    
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
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.progress)
                        .frame(width: 200)
                    
                    if viewModel.isTimerComplete {
                        Text("Timer Complete!")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
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
    
    @State private var inputBuffer = ""
    
    var body: some View {
        TextField("00", text: $text)
            .font(.system(size: 64, design: .monospaced))
            .bold()
            .multilineTextAlignment(.center)
            .frame(width: 80, height: 80)
            .focused(focusedField, equals: field)
            .textFieldStyle(.plain)
            .background(Color.clear)
            .onChange(of: text) { oldValue, newValue in
                handleInput(newValue)
            }
            .onChange(of: focusedField.wrappedValue) { oldValue, newValue in
                if newValue == field {
                    // When field gains focus, reset to "00" and clear buffer
                    text = "00"
                    inputBuffer = ""
                }
            }
    }
    
    private func handleInput(_ newValue: String) {
        // Extract only digits
        let digits = newValue.filter { $0.isNumber }
        
        if digits.isEmpty {
            text = "00"
            inputBuffer = ""
            return
        }
        
        // Right-to-left input: new digits go to the right, old digits shift left
        // Take last 2 digits (rightmost digits)
        let lastTwo = String(digits.suffix(2))
        inputBuffer = lastTwo
        
        if let intValue = Int(lastTwo) {
            // Clamp to max value
            let clamped = min(intValue, maxValue)
            text = String(format: "%02d", clamped)
        } else {
            text = "00"
        }
    }
}

struct TimerProgressView: View {
    let viewModel: SessionViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: viewModel.progress)
                .frame(width: 200)
            
            if viewModel.isTimerComplete {
                Text("Timer Complete!")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else {
                Text("Remaining: \(formatTime(viewModel.remainingTime))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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


struct SessionControlsView: View {
    let viewModel: SessionViewModel
    
    private var isPaused: Bool {
        viewModel.currentSession != nil && !viewModel.isRunning
    }
    
    var body: some View {
        HStack(spacing: 20) {
            if viewModel.isRunning {
                // Show Pause button when running
                Button {
                    viewModel.pauseSession()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(width: 120, height: 50)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                
                // Show Stop button to end session
                Button {
                    viewModel.stopSession()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(width: 120, height: 50)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            } else if isPaused {
                // Show Resume button when paused
                Button {
                    viewModel.resumeSession()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .frame(width: 120, height: 50)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                
                // Show Stop button to end session
                Button {
                    viewModel.stopSession()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(width: 120, height: 50)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            } else {
                // Show Start button when not running and not paused
                Button {
                    viewModel.startSession()
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .frame(width: 120, height: 50)
                        .background(viewModel.isTimerEnabled ? Color.green : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.isTimerEnabled)
            }
        }
    }
}

