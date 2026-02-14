//
//  DeepEyeRoot.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import SwiftUI

struct DeepEyeRoot: View {
    @StateObject private var appModel = AppModel()
    @StateObject private var spectrum = SpectrumProvider()
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.DeepEye.void.edgesIgnoringSafeArea(.all)
            
            // Content Layer
            VStack(spacing: 30) {

                // Header
                HStack {
                    Text("DEEP EYE")
                        .font(.deepHeading)
                        .foregroundColor(.DeepEye.accent)
                        .deepGlow()
                    
                    Spacer()
                    
                    // Preset Menu
                    Menu {
                        ForEach(appModel.presets, id: \.id) { preset in
                            Button(preset.name) { appModel.selectPreset(preset) }
                        }
                        Divider()
                        Button("Save New Preset") {
                            appModel.savePreset(name: "User \(Int(Date().timeIntervalSince1970))")
                        }
                    } label: {
                        Text(appModel.presets.first(where: { $0.id == appModel.selectedPresetId })?.name ?? "Presets")
                            .font(.caption)
                            .foregroundColor(.DeepEye.accent)
                            .padding(6)
                            .background(Color.DeepEye.surface)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    // Input Selector
                    Menu {
                        Button("System Audio") { appModel.selectSystemAudio() }
                        Divider()
                        ForEach(appModel.inputDevices, id: \.id) { device in
                            Button(device.name) { appModel.selectInputDevice(device) }
                        }
                        Divider()
                        Button("Refresh") { appModel.refreshInputDevices() }
                    } label: {
                        HStack {
                            Image(systemName: appModel.activeInputDevice == nil ? "desktopcomputer" : "mic.fill")
                                .foregroundColor(.DeepEye.accent)
                            Text(appModel.activeInputDevice?.name ?? "System Audio")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.DeepEye.surface)
                        .cornerRadius(8)
                    }
                    
                    // Mute Toggle
                    Button(action: {
                        appModel.toggleMute()
                    }) {
                        Image(systemName: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                            .foregroundColor(appModel.isMuted ? .red : .DeepEye.accent)
                    }
                    
                    // FX Selector
                    PluginSelector(appModel: appModel)
                }
                .padding(.horizontal)
                
                // Visualizer Area
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.DeepEye.surface)
                        .frame(height: 160)
                        .deepGlass()
                    
                    // Spectrum Bars (Simple Canvas Implementation)
                    TimelineView(.animation) { context in
                        Canvas { ctx, size in
                            let width = size.width
                            let height = size.height
                            let barWidth = width / CGFloat(spectrum.magnitudes.count)
                            
                            for (index, magnitude) in spectrum.magnitudes.enumerated() {
                                let x = CGFloat(index) * barWidth
                                let barHeight = CGFloat(magnitude) * height
                                let rect = CGRect(x: x, y: height - barHeight, width: barWidth - 1, height: barHeight)
                                
                                ctx.fill(Path(rect), with: .color(.DeepEye.accent.opacity(0.8)))
                            }
                        }
                    }
                    .frame(height: 140)
                    .padding(.horizontal, 10)
                }
                


                // Controls Area
                HStack(spacing: 24) {
                    // Pre-Amp / Input Gain
                    DeepKnob(value: $appModel.volume, range: 0...2, title: "GAIN")
                    
                    // EQ Section
                    EQBandControl(gain: $appModel.bassGain, killed: $appModel.bassKilled, band: .bass, title: "LOW", appModel: appModel)
                    EQBandControl(gain: $appModel.midGain, killed: $appModel.midKilled, band: .mid, title: "MID", appModel: appModel)
                    EQBandControl(gain: $appModel.trebleGain, killed: $appModel.trebleKilled, band: .treble, title: "HI", appModel: appModel)
                    
                    // DJ Filter
                    FilterKnob(appModel: appModel)
                    

                    VStack(spacing: 2) {
                        DeepKnob(value: $appModel.volume, range: 0...1, title: "MASTER")
                        
                        Button(action: {
                            appModel.toggleLimiter()
                        }) {
                            Text("LIMIT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(appModel.limiterEnabled ? .red : .gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(appModel.limiterEnabled ? Color.red.opacity(0.15) : Color.DeepEye.surface)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(appModel.limiterEnabled ? Color.red : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            appModel.sidechain.isEnabled.toggle()
                        }) {
                            Text("DUCK")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(appModel.sidechain.isEnabled ? .cyan : .gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(appModel.sidechain.isEnabled ? Color.cyan.opacity(0.15) : Color.DeepEye.surface)
                                .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
        .onAppear {
            appModel.refreshInputDevices()
            appModel.loadPresets()
        }
    }
}

struct FilterKnob: View {
    @ObservedObject var appModel: AppModel
    @State private var value: Double = 0.5
    
    var body: some View {
        DeepKnob(value: $value, range: 0...1, title: "FILTER", showCenterDetent: true)
            .onChange(of: value) { newValue in
                appModel.setFilterValue(newValue)
            }
    }
}

struct EQBandControl: View {
    @Binding var gain: Double
    @Binding var killed: Bool
    var band: AppModel.DJBand
    var title: String
    @ObservedObject var appModel: AppModel
    
    var body: some View {
        VStack(spacing: 4) {
            DeepKnob(value: $gain, range: -12...12, title: title, showCenterDetent: true)
                .opacity(killed ? 0.3 : 1.0)
                .allowsHitTesting(!killed)
                .onChange(of: gain) { newValue in
                    appModel.setBandGain(band, value: newValue)
                }
            
            Button(action: {
                appModel.toggleKill(band)
            }) {
                Text("KILL")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(killed ? .white : .gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(killed ? Color.red : Color.DeepEye.surface)
                    .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct DeepEyeRoot_Previews: PreviewProvider {
    static var previews: some View {
        DeepEyeRoot()
    }
}
