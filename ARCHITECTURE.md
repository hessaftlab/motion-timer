# Motion Timer — Architecture

## Overview
Native macOS menu bar + floating window timer app built with SwiftUI.
Phase 1: Standalone timer. Phase 2: Motion.ai API integration.

## App Structure

```
MotionTimer/
├── App/
│   ├── MotionTimerApp.swift          # App entry point, menu bar setup
│   └── AppState.swift                # Global observable state
├── Views/
│   ├── TimerWindow/
│   │   ├── TimerView.swift           # Main timer display (countdown/countup)
│   │   ├── TimerControlsView.swift   # Start/pause/reset buttons
│   │   └── TimerProgressRing.swift   # Animated circular progress indicator
│   ├── MenuBar/
│   │   ├── MenuBarView.swift         # Menu bar popover UI
│   │   └── MenuBarIcon.swift         # Dynamic menu bar icon (shows time)
│   └── Settings/
│       └── SettingsView.swift        # Preferences (appearance, sounds, defaults)
├── Models/
│   ├── TimerModel.swift              # Timer logic (countdown/countup/state machine)
│   ├── TimerMode.swift               # Enum: countdown, countup
│   └── TimerPreset.swift             # Saved timer presets (25min, 50min, custom)
├── Services/
│   ├── MotionAPIService.swift        # Phase 2: Motion.ai REST client
│   ├── MotionTaskPoller.swift        # Phase 2: Poll for active task changes
│   └── NotificationService.swift     # Local notifications on timer complete
├── Utilities/
│   ├── TimeFormatter.swift           # HH:MM:SS formatting
│   ├── WindowManager.swift           # Floating window positioning, always-on-top
│   └── Constants.swift               # Colors, sizes, defaults
└── Resources/
    └── Assets.xcassets               # App icon, colors
```

## Key Design Decisions

### Window Behavior
- **Floating panel** (NSPanel with .floating level) — stays above other windows
- **Draggable** — user positions it where they want
- **Compact** — roughly 200x200pt default, resizable
- **Transparency** — frosted glass / vibrancy effect for modern macOS look

### Menu Bar
- Lives in system menu bar with dynamic icon showing remaining time
- Click opens popover with quick controls
- Right-click for settings/quit

### Timer Engine
- `TimerModel` is an ObservableObject with @Published properties
- Uses `Timer.publish` for 1-second ticks
- State machine: idle → running → paused → completed
- Supports both countdown (set duration, counts to zero) and countup (stopwatch)

### Aesthetics
- Dark frosted glass background (NSVisualEffectView / .ultraThinMaterial)
- Large monospaced timer digits
- Circular progress ring with gradient animation
- Minimal chrome — no title bar, rounded corners
- Accent colors: subtle blue/purple gradient

### Phase 2: Motion Integration
- REST client using URLSession + async/await
- Poll Motion API every 30-60s for current scheduled task
- When task changes → auto-update timer with task name + duration
- Display task name above timer digits
- API key stored in macOS Keychain

## Build Target
- macOS 14+ (Sonoma)
- Swift 6 / SwiftUI
- Xcode 16+
- No external dependencies (pure Apple frameworks)
