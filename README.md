# Uptime

A macOS work session tracking app with timer functionality, calendar visualization, and widget support.

<img width="630" height="421" alt="Screenshot 2025-12-28 at 3 13 43 PM" src="https://github.com/user-attachments/assets/cbdfb632-e966-4fe4-88c9-c511a753412a" />

<img width="360" height="180" alt="Screenshot 2025-12-28 at 3 13 58 PM" src="https://github.com/user-attachments/assets/3cb2bf64-ce38-4df1-95f9-4cdd069432e7" />

[App Store](https://apps.apple.com/us/app/uptime-tracker/id6757130969?mt=12)

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
