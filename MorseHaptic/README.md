# Morse — Haptic Morse Code Player

A native iOS app that converts text into Morse code and plays it back using precise iPhone haptics synced with a fluid, animated visual timeline.

## Features

- **Live Text → Morse Conversion** — Type any word or phrase, see it instantly rendered as dots and dashes
- **Core Haptics Playback** — Dots feel like short, soft taps; dashes are longer, stronger pulses; word gaps have a subtle "breath" haptic to maintain presence
- **Animated Visual Timeline** — Horizontal scrolling timeline with glowing active elements, smooth spring animations, and blur/scale/opacity transitions
- **Radial Visualization** — Toggle to a circular Morse display with elements arranged around a ring
- **Speed Control** — Adjustable WPM (3–25) with a custom gradient slider
- **Playback Controls** — Play / Pause / Stop with loop toggle
- **Dark-Mode First** — Minimal, high-contrast, Apple-like design

## Architecture

```
MorseHaptic/
├── App/
│   ├── MorseHapticApp.swift      # Entry point
│   └── ContentView.swift          # Main UI composition
├── Models/
│   └── MorseModels.swift          # Signal types, timing config, sequences
├── Engine/
│   ├── MorseEncoder.swift         # Text → Morse encoding (pure functions)
│   └── PlaybackCoordinator.swift  # Orchestrates haptics + visuals sync
├── Haptics/
│   └── HapticEngine.swift         # Core Haptics pattern builder & player
└── Views/
    ├── InputView.swift            # Text input with live Morse preview
    ├── MorseTimelineView.swift    # Horizontal + radial visualizations
    ├── PlaybackControlsView.swift # Play/pause/stop buttons
    └── Components/
        ├── SignalElementView.swift # Dot/dash visual elements
        ├── SpeedControlView.swift  # WPM slider + loop toggle
        └── MorseTextView.swift     # Morse string display + active char
```

## Requirements

- iOS 17.0+
- iPhone (haptics require physical device)
- Xcode 15+
- Swift 5.9+

## How to Run

1. Open `MorseHaptic.xcodeproj` in Xcode
2. Select an iPhone target (physical device recommended for haptics)
3. Build and run (⌘R)

## Design Principles

- **Tactile & Elegant** — Haptics are carefully tuned: dots use lighter intensity/sharpness, dashes are heavier with a transient "attack" at the start
- **Motion > Decoration** — Spring animations, glow effects, and scale transitions communicate state without text clutter
- **Architecture Separation** — Encoding, haptics, and rendering are fully decoupled. The PlaybackCoordinator is the single source of truth
