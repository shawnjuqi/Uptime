# Uptime

A macOS work session tracking app with timer functionality, calendar visualization, and widget support.

<img width="630" height="421" alt="Screenshot 2025-12-28 at 3 13 43 PM" src="https://github.com/user-attachments/assets/cbdfb632-e966-4fe4-88c9-c511a753412a" />

<img width="360" height="180" alt="Screenshot 2025-12-28 at 3 13 58 PM" src="https://github.com/user-attachments/assets/3cb2bf64-ce38-4df1-95f9-4cdd069432e7" />

[App Store](https://apps.apple.com/us/app/uptime-tracker/id6757130969?mt=12)

## Features

- Customizable countdown timer (hours:minutes:seconds)
- Start, pause, resume, and stop session controls
- Auto-pauses when your Mac goes to sleep so idle time isn't counted
- Month and year calendar views shaded by time invested, with per-day detail
- Stats with today, this week vs. last week, current streak, and a 7-day chart
- Menu bar integration showing timer status
- macOS widget with a daily progress ring and contribution grid
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

Add the Uptime widget to your Mac desktop or Notification Center:

1. Run the **Uptime** scheme in Xcode (not the widget extension scheme alone) and leave the app launched once
2. Right-click the desktop → **Edit Widgets**, or open Notification Center → **Edit Widgets**
3. Search for **Uptime**
4. Choose Small, Medium, or Large

The widget shows today’s progress and a recent-activity grid.

## Acknowledgments

- Built with SwiftUI and CoreData
- Widget extension powered by WidgetKit
