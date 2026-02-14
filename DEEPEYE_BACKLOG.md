# DeepEye EqMac - Future Backlog (Post-v2.0)

The v2.0 "DeepEye" release successfully established the SwiftUI foundation and core DJ features. The following items are recommended for future development (v2.1+).

## 🎛 Pro Audio Features

- [x] **VST/AU Plugin Hosting**: Allow users to load 3rd party effects (Reverb, Delay) into the chain. (Completed in v2.1)
- [x] **MIDI Mapping**: Bind hardware DJ controllers (Pioneer, Numark) to the DeepEye knobs via MIDI. (Default map: CC1=Vol, CC2=Filt, CC3-5=Eq)
- [x] **Sidechain Compression**: precise ducking for voiceovers (Mic Input ducks System Audio). (Implemented via 'DUCK' button)

## 🎨 UI/UX Improvements

- [ ] **Resizable Window**: Currently fixed size. Implement responsive SwiftUI layout for fullscreen mode.
- [ ] **Theming Engine**: Allow users to swap the "DeepEye" (Teal/Pink) palette for "Solar" (Gold/Red) or "Lunar" (White/Silver).
- [ ] **Touch Bar Support**: Map EQ cuts and Filter sweeps to the MacBook Pro Touch Bar.

## 🔧 Technical Debt / Refactoring

- [ ] **Remove Angular**: Completely delete the legacy `www/` folder and `UI/` web view code to reduce app size.
- [ ] **Pure SwiftUI Lifecycle**: Migrate from `AppDelegate` to `@main DeepEyeApp` (blueprint provided in `DeepEyeApp.swift`).
- [ ] **Metal Visualization**: Upgrade `SpectrumProvider` from CoreGraphics `Canvas` to a custom `MetalKit` shader for 120fps fluid particles.

## 🐛 Known Considerations

- **High CPU Usage**: The current FFT Analyzer runs on the main thread via Timer. Moving this to a background `DispatchSourceTimer` or `CADisplayLink` would optimize battery life.
- **Input Switching**: Switching inputs causes a brief audio dropout (Engine restart). Implementing `AVAudioEngine` format conversion on the fly would allow seamless switching.
