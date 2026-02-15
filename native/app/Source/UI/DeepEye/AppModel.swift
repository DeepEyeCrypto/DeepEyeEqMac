//
//  AppModel.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

class AppModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var statusMessage: String = "Ready"
    
    // Audio State
    @Published var volume: Double = 0.8 {
        didSet { updateVolume() }
    }
    @Published var filter: Double = 0.5 {
        didSet { updateFilter() }
    }
    
    @Published var bass: Double = 0.5 {
        didSet { updateEQ() }
    }
    @Published var mid: Double = 0.5 {
        didSet { updateEQ() }
    }
    @Published var treble: Double = 0.5 {
        didSet { updateEQ() }
    }
    
    var midiManager = MIDIManager()
    
    init() {
        // Listen for Application events
        setupListeners()
        setupMIDI()
        
        // Simulate initialization delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
        }
    }
    
    @Published var pluginManager = PluginManager()
    @Published var activePluginName: String? = nil
    
    private func setupListeners() {
        // Bind to Application.enabled logic etc.
    }
    
    func setupMIDI() {
        // CC1: Volume
        midiManager.map(cc: 1) { [weak self] val in
            DispatchQueue.main.async { self?.volume = val }
        }
        // CC2: Filter
        midiManager.map(cc: 2) { [weak self] val in
            DispatchQueue.main.async { self?.filter = val }
        }
        // CC3: Bass
        midiManager.map(cc: 3) { [weak self] val in
            DispatchQueue.main.async { self?.bass = val }
        }
        // CC4: Mid
        midiManager.map(cc: 4) { [weak self] val in
            DispatchQueue.main.async { self?.mid = val }
        }
        // CC5: Treble
        midiManager.map(cc: 5) { [weak self] val in
            DispatchQueue.main.async { self?.treble = val }
        }
    }
    
    private func updateVolume() {
         Application.dispatchAction(VolumeAction.setGain(volume, false))
    }
    
    private func updateFilter() {
        Application.engine?.filter.value = Float(filter)
    }
    
    private func updateEQ() {
        // Map 0...1 to -24...24
        let b = (bass - 0.5) * 48
        let m = (mid - 0.5) * 48
        let t = (treble - 0.5) * 48
        
        let gains = BasicEqualizerPresetGains(bass: b, mid: m, treble: t)
        
        // Update "manual" preset (assumes Manual is selected or we switch to it)
        // Check if current preset is manual? For simplicity, we force update manual and select it.
        BasicEqualizer.updatePreset(id: "manual", peakLimiter: false, gains: gains)
        
        // Dispatch select if not already selected (optimization: ReSwift handles diff)
        // But to avoid event loop, we might want to check state.
        // For now, always dispatch.
        Application.dispatchAction(BasicEqualizerAction.selectPreset("manual", false))
    }
    
    func loadPlugin(_ plugin: AudioPlugin) {
        statusMessage = "Loading \(plugin.name)..."
        pluginManager.loadPlugin(plugin) { [weak self] avUnit in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let avUnit = avUnit else {
                    self.statusMessage = "Failed to load \(plugin.name)"
                    return
                }
                
                // Insert into Engine
                if let engine = Application.engine {
                    engine.insertPlugin(avUnit)
                    self.activePluginName = plugin.name
                    self.statusMessage = "Loaded \(plugin.name)"
                } else {
                    self.statusMessage = "Engine not ready"
                }
            }
        }
    }
    
    func removePlugin() {
        if let engine = Application.engine {
            engine.removePlugin()
            self.activePluginName = nil
            self.statusMessage = "Plugin removed"
        }
    }
}
