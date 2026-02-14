# DeepEye UI Architecture

This directory contains the modernized SwiftUI interface for eqMac, developed as part of the "DeepEye" initiative (2024).

## Core Components

### 1. AppModel (ViewModel)

- Acts as the bridge between Legacy ReSwift Store and SwiftUI Views.
- Manages local state (Volume, EQ, Filter) for immediate UI feedback (60fps).
- Throttles updates from the Store to prevent UI lag.
- Implements "Ghost" state logic for Kill Switches (UI shows knob position while Engine kills frequency).

### 2. DeepEyeRoot (View)

- The main window composition.
- Layout: Header -> Spectrum Visualizer -> Gain -> 3-Band EQ (with Kill) -> DJ Filter -> Master.

### 3. Components

- **DeepKnob**: A custom rotary control with vertical drag interaction and "Glow" effects. Supports -12...+12 ranges and center detents.
- **SpectrumProvider**: Real-time FFT Analysis using vDSP (Accelerate framework). Processes audio buffer into 64 visual bars.
- **DesignSystem**: Centralized definition of "DeepEye" colors (Teal/Pink/Void) and modifiers (Glassmorphism).

## Audio Integration

- **DJFilter**: A new custom Audio Node (AVAudioUnitEQ) inserted into the engine chain.
  - Frequency response morphs from LPF (Low Pass) to HPF (High Pass) based on a single 0.0-1.0 parameter.
- **BasicEqualizer**: The legacy 10-band EQ is controlled as a 3-Band DJ EQ (Bass/Mid/High) via `AppModel`.

## Development Notes

- The entry point is `Application.showDeepEye()`, which creates an `NSHostingController`.
- `DeepEyeApp.swift` is a placeholder for future full-SwiftUI lifecycle migration.
- `SpectrumProvider` requires the Audio Engine to be running to capture buffers.
