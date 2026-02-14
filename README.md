# DeepEye EqMac v2.0 - AI Enhanced DJ Edition

> **"The Void Update"** - A complete rewrite of the UI in SwiftUI with professional DJ capabilities.

![Build Status](https://github.com/DeepEyeCrypto/DeepEyeEqMac/actions/workflows/macos.yaml/badge.svg) ![Version](https://img.shields.io/badge/Version-2.0.0-blue) ![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-orange)

## 🚀 Overview

**DeepEye EqMac** transforms the classic utility into a performance-grade audio tool. By replacing the legacy web-based UI with a native, hardware-accelerated **SwiftUI** interface, we've unlocked features previously impossible:

- **Zero-Latency Control**: Knob twists interact directly with the C++ Audio Engine.
- **60fps Visualization**: Metal/vDSP powered Spectrum Analyzer.
- **Pro Audio Routing**: Seamless Input/Output switching and VST hosting.

---

## 🌟 Key Features

### 🎛 The DJ Engine

- **3-Band Kill EQ**: Dedicated Low/Mid/Hi knobs with "Kill Switches" (-24dB cut).
- **Morphing Filter**: A single knob that sweeps from Low Pass to High Pass (Pioneer DJ style).
- **Brickwall Limiter**: Safety dynamics processor to prevent clipping at high volumes.

### 🔌 Studio Connectivity

- **Input Routing**: Switch between **System Audio** (Loopback) and **Hardware Inputs** (Microphone, Line-In).
- **VST/AU Hosting**: Load any macOS Audio Unit effect (Reverb, Delay, Distortion) directly into the chain.
- **Sidechain Ducking**: Automatically lower the music volume when you speak (Talkover).

### 🎹 Hardware Control

- **MIDI Mapping**: Connect any USB MIDI Controller.
  - **CC 1**: Master Volume
  - **CC 2**: DJ Filter
  - **CC 3/4/5**: Low / Mid / High EQ

---

## 🛠 Installation & Build

### Prerequisites

- Xcode 13+
- macOS 11.0 (Big Sur) or later.
- CocoaPods (`sudo gem install cocoapods`)

### Build Instructions

1. **Clone & Install**:

   ```bash
   git clone https://github.com/your-repo/DeepEyeEqMac.git
   cd DeepEyeEqMac/native/app
   pod install
   ```

2. **Open Workspace**:
   Open `eqMac.xcworkspace` (NOT the .xcodeproj).
3. **Run**:
   Select the `eqMac` scheme and press **Cmd+R**.

---

## 🏗 Architecture

The project has been modernized from a Hybrid (Electron-like) app to a Native macOS App:

- **Legacy**: Angular (JS) -> WebSocket -> C++ Engine.
- **DeepEye (v2.0)**: **SwiftUI** -> **AppModel (Combine)** -> **C++ Engine**.

### Core Files

- `DeepEyeRoot.swift`: The main UI composition.
- `AppModel.swift`: The brain connecting UI to Audio.
- `Engine.swift`: The enhanced AVAudionEngine wrapper.
- `PluginManager.swift`: VST/AU Scanner and Host.
- `MIDIManager.swift`: CoreMIDI implementation.

---

*Built with ❤️ by the DeepEye Agentic AI Team.*
