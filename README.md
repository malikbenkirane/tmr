# too_many_tabs - Routine Tracker

A Flutter app for tracking daily routines with time goals, notifications, and data management. 
Designed for iOS with Material 3 design and local data storage.

## ✨ Features
- Create, start/stop, archive, and restore routines with time goals
- Real-time tracking with dynamic goal timers
- 5/10-minute warning notifications and goal completion alerts
- SQLite database with logging, export, and archive support
- Daily automatic reset of spent time
- Material 3 color schemes with seed-based generation
- Polished UI with slide-up panel interface

## 🚀 Quick Start

### Prerequisites
- Flutter, Dart and Xcode. We were happy with the following
  ```
  $ flutter version
  Flutter 3.38.4 • channel stable • git@github.com:flutter/flutter.git
  Framework • revision 66dd93f9a2 (3 days ago) • 2025-12-03 14:56:10 -0800
  Engine • hash 360877569ab6632a564a0a8a815b2e0fe5ae294a (revision a5cb96369e) (3 days ago) •
  2025-12-03 20:56:06.000Z
  Tools • Dart 3.10.3 • DevTools 2.51.1
  
  $ xcodebuild -version
  Xcode 26.1.1
  Build version 17B100
  ```
- `atlas` from [atlasgo](https://atlasgo.io/getting-started) for migrations
  ```bash
  atlas migrate apply --url sqlite://assets/state.db
  ```

### Installation
```bash
# Clone and install dependencies
git clone https://github.com/to0-m4ny-t4bs/too-many-tabs-routines-poc --depth=1
cd too-many-tabs
flutter pub get

# iOS dependencies (macOS only)
cd ios && pod install && cd ..
```

### Build & Run
```bash
# Debug build
flutter run

# Release build
flutter build ios --release          # iOS (requires macOS)
```

### Install Release Build
**iOS:** Open `ios/Runner.xcworkspace` in Xcode and archive for distribution.

### Debugging
```bash
flutter run --debug        # Debug mode
flutter logs               # View logs
flutter test               # Run tests
```

## 📱 App Structure
- `lib/data/` - Main app screens
- `lib/services/` - Database and business logic
- `lib/widgets/` - Reusable components
- `lib/utils/` - Utilities and formatters

## 🔧 Troubleshooting
- **Build issues:** Run `flutter clean && flutter pub get`
- **iOS build:** Re-run `pod install` in `ios/` folder
- **Notifications:** Check device permission settings

---

Built with ❤️ using Flutter
