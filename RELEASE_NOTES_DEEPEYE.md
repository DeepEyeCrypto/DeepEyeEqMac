# DeepEye EqMac - v2.1 "The Pro Audio Update"

**Release Notes & Setup Guide**

## 🚀 Overview

**DeepEye EqMac v2.1** takes the native SwiftUI foundation established in v2.0 and supercharges it with professional audio processing capabilities. This release effectively completes the transition from a consumer utility to a pro-grade audio tool.

---

## 🌟 New Features in v2.1

### 1. 🎛 VST/AU Plugin Hosting (New!)

- **Bring Your Own Effects**: You can now load any 3rd-party Audio Unit (AU) plugin directly into the DeepEye signal chain.
- **Seamless Integration**: Plugins sit between the Equalizer and the Limiter, perfect for adding Reverb, Delay, or advanced Saturation to your output.
- **Dedicated UI**: A new plugin selector allows for easy insertion and removal of effects.

### 2. 🎚 MIDI Mapping

- **Hardware Control**: Connect your favorite MIDI DJ Controller (Pioneer, Numark, etc.).
- **Zero-Config Mapping**:
  - **CC 1**: Volume
  - **CC 2**: DJ Filter (Low/High Pass)
  - **CC 3**: Bass (Low)
  - **CC 4**: Mid
  - **CC 5**: Treble (High)
- **Bi-Directional**: UI updates instantly when you turn hardware knobs.

### 3. 📉 Sidechain "Talkover"

- **Auto-Ducking**: The new **DUCK** button activates a sidechain compressor.
- **Voice Priority**: When you speak into your microphone, the system audio (music) automatically lowers in volume, ensuring your voice is heard clearly. Perfect for podcasting or DJ announcements.

### 4. ⚡️ Performance & Visualization

- **Real-Time FFT**: The Spectrum Analyzer is now powered by Apple's `Accelerate` framework (vDSP), running on a background thread.
- **High FPS**: Visualization is buttery smooth (60fps) without blocking the main UI thread.
- **Zero Bloat**: The legacy Angular/Web UI has been completely removed, significantly reducing app size and memory footprint.

---

## 🛠 Technical Enhancements

- **Pure Native**: The app now runs on a pure SwiftUI lifecycle (`@main DeepEyeApp`), removing the legacy `AppDelegate` complexity.
- **Optimized Engine**: Audio graph management has been refactored for better stability when switching devices.

---

## ⚡️ Quick Start

1. **Host Plugins**: Click the "+" icon in the effects section to load your favorite Reverb or Delay.
2. **Connect MIDI**: Plug in a controller sending CC messages 1-5 to take control.
3. **Duck**: Enable your mic input and hit "DUCK" to test the automatic voice-over attenuation.

---

*Built with ❤️ by the DeepEye Team (Agentic AI).*
