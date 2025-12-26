import SwiftUI

struct SessionView: View {
    let viewModel: SessionViewModel
    @State private var showTimerSettings = false
    @State private var customHours = 1
    @State private var customMinutes = 0
    
    var body: some View {
        VStack {
            TimerDisplayView(viewModel: viewModel)
            
            if !viewModel.isRunning {
                TimerSettingsView(
                    viewModel: viewModel,
                    showCustomTimer: $showTimerSettings
                )
            }
            
            SessionControlsView(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showTimerSettings) {
            CustomTimerView(
                hours: $customHours,
                minutes: $customMinutes,
                onSave: {
                    viewModel.setCustomDuration(hours: customHours, minutes: customMinutes)
                    showTimerSettings = false
                },
                onCancel: {
                    showTimerSettings = false
                }
            )
        }
    }
}

struct TimerDisplayView: View {
    let viewModel: SessionViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Work Session")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text(formatTime(viewModel.elapsedTime))
                .font(.system(size: 64, design: .monospaced))
                .bold()
                .foregroundStyle(viewModel.isTimerComplete ? .green : .primary)
            
            if viewModel.isTimerEnabled && viewModel.isRunning {
                TimerProgressView(viewModel: viewModel)
            } else if viewModel.isTimerEnabled && !viewModel.isRunning {
                Text("Target: \(formatTime(viewModel.targetDuration))")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
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

struct TimerSettingsView: View {
    let viewModel: SessionViewModel
    @Binding var showCustomTimer: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Set Timer")
                .font(.headline)
            
            HStack(spacing: 12) {
                PresetButton(title: "30m", minutes: 30, viewModel: viewModel)
                PresetButton(title: "1h", minutes: 60, viewModel: viewModel)
                PresetButton(title: "2h", minutes: 120, viewModel: viewModel)
                PresetButton(title: "Custom", minutes: nil, viewModel: viewModel) {
                    showCustomTimer = true
                }
            }
            
            if viewModel.isTimerEnabled {
                Button("Disable Timer", action: viewModel.disableTimer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 12))
    }
}

struct PresetButton: View {
    let title: String
    let minutes: Int?
    let viewModel: SessionViewModel
    var action: (() -> Void)?
    
    init(title: String, minutes: Int?, viewModel: SessionViewModel, action: (() -> Void)? = nil) {
        self.title = title
        self.minutes = minutes
        self.viewModel = viewModel
        self.action = action
    }
    
    private var isSelected: Bool {
        guard viewModel.isTimerEnabled else { return false }
        
        if let minutes = minutes {
            let presetDuration = TimeInterval(minutes * 60)
            return abs(viewModel.targetDuration - presetDuration) < 0.1
        } else {
            let presetDurations: [TimeInterval] = [30 * 60, 60 * 60, 120 * 60]
            let matchesPreset = presetDurations.contains { abs(viewModel.targetDuration - $0) < 0.1 }
            return !matchesPreset
        }
    }
    
    var body: some View {
        Button {
            if let minutes = minutes {
                viewModel.setPresetDuration(minutes)
            } else {
                action?()
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 60, height: 32)
                .background(isSelected ? Color.blue : Color.black)
                .foregroundStyle(isSelected ? .white : .white)
                .clipShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct SessionControlsView: View {
    let viewModel: SessionViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            if viewModel.isRunning {
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
                Button {
                    viewModel.startSession()
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .frame(width: 120, height: 50)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CustomTimerView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Custom Timer")
                .font(.title2)
                .bold()
            
            HStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Stepper(value: $hours, in: 0...23) {
                        Text("\(hours)")
                            .font(.title3)
                            .frame(width: 50)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Minutes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Stepper(value: $minutes, in: 0...59) {
                        Text("\(minutes)")
                            .font(.title3)
                            .frame(width: 50)
                    }
                }
            }
            .padding()
            
            HStack(spacing: 16) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                
                Button("Set Timer", action: onSave)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(width: 300)
    }
}
