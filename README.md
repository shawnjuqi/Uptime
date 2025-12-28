# Uptime

A macOS work session tracking app with timer functionality, calendar visualization, and widget support.

## Features

- Customizable countdown timer (hours:minutes:seconds)
- Start, pause, resume, and stop session controls
- Calendar view with work day visualization (GitHub-style contribution grid)
- Daily stats tracking and historical data
- Menu bar integration showing timer status
- macOS Widget extension for quick activity overview
- Persistent storage with CoreData

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for development)

## Installation

1. Clone and open in Xcode
2. Build and run
3. Set your timer duration and start tracking work sessions

## Configuration

### Testing Mode

Enable testing mode via the menu bar: `⌘⌥T` or use the Command menu "Test" → "Show Testing Mode". This allows you to:
- Create test sessions for any date
- Delete sessions for specific dates
- Clear all session data

### Widget

Add the Uptime widget to your macOS notification center:
1. Open Notification Center
2. Click "Edit Widgets"
3. Search for "Uptime"
4. Choose from Small, Medium, or Large sizes

The widget displays a contribution-style calendar grid showing your work activity over time.

## Acknowledgments

- Built with SwiftUI and CoreData
- Widget extension powered by WidgetKit