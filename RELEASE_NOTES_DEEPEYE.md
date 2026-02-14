# DeepEye EqMac - v2.0 "The DJ Update"

**Release Notes & Setup Guide**

## 🚀 Overview

**DeepEye EqMac** is a total transformation of the classic eqMac application, rebuilding the interface from the ground up using **SwiftUI** and introducing professional **DJ Performance Features**.

This release (Milestone 3) brings the application to a fully functional "Pro" state, suitable for live performance and advanced audio routing.

---

## 🌟 New Features

### 1. The "DeepEye" Interface

- **Complete UI Overhaul**: Replaced the legacy Angular/Web UI with a high-performance, native macOS **SwiftUI** interface.
- **"Void" Aesthetic**: A dark, contrast-heavy design system built for low-light environments (clubs/studios).
- **Glassmorphism**: subtle blur effects and glowing controls for better visibility.

### 2. DJ Performance Tools

- **3-Band Kill EQ**:
  - Dedicated **Low / Mid / Hi** knobs tailored for mixing.
  - **Kill Switches**: Instantly cut (-24dB) any frequency band. Push again to restore.
- **DJ Filter Color FX**:
  - A single **FILTER** knob that morphs from **Low Pass** (turn left) to **High Pass** (turn right).
  - Neutral center position (12 o'clock) bypasses the effect.
- **Spectrum Analyzer**:
  - Real-time, hardware-accelerated (Metal/vDSP) audio visualizer.
  - 64-band frequency display running at 60fps.

### 3. Pro Audio Capabilities

- **Input Routing**: Switch seamlessly between System Audio and Hardware Inputs.
- **Brickwall Limiter**: dedicated safety dynamics processor.
- **Preset Management**: Save/Load custom EQ curves.
- **VST/AU Plugin Hosting**: Load 3rd party effects (Reverb, Delay) directly into the chain.
- **MIDI Mapping**: Control EQ and Volume with hardware DJ controllers (CC1-CC5).
- **Sidechain Ducking**: Automatically lower music volume when speaking into the microphone ("Talkover").

---

## 🛠 Technical Details

### Architecture

- **AppModel Bridge**: A robust ViewModel layer connects the reactive SwiftUI frontend with the existing C++/Swift audio engine.
- **Safety**:
  - **Safe Start**: Volume is automatically capped at 50% on launch if it was left dangerously high.
  - **Latency**: EQ and Filter changes bypass the state store for near-zero latency response.

### New Files

- `Native/App/Source/UI/DeepEye/`
  - `DeepEyeRoot.swift`: Main Window composition.
  - `AppModel.swift`: State management and Audio Engine bridge.
  - `DeepKnob.swift`: Custom rotary control component.
  - `SpectrumProvider.swift`: FFT Audio Analysis engine.
- `Native/App/Source/Audio/Effects/`
  - `DJFilter.swift`: Custom Dual-Mode Filter node.
  - `Limiter.swift`: Brickwall Limiter node.

---

## ⚡️ Quick Start

1. **Launch**: Open `DeepEye EqMac`.
2. **Route**: Ensure "System Audio" is selected in the top right menu for general music listening.
3. **Play**: Start music on Spotify/Apple Music.
4. **Mix**:
   - Drag the **FILTER** knob to sweep frequencies.
   - Use **KILL** buttons to drop the bass.
   - Save your perfect curve in the **Presets** menu.

---

*Built with ❤️ by the DeepEye Team (Agentic AI).*
