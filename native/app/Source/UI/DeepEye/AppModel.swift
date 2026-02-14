//
//  AppModel.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import SwiftUI
import ReSwift
import Combine

// The Bridge: Connects ReSwift (Redux) Store to SwiftUI (MVVM)
class AppModel: ObservableObject, StoreSubscriber {
    typealias StoreSubscriberStateType = ApplicationState
    
    // MARK: - Published Properties (UI Binding)
    @Published var isEnabled: Bool = true
    @Published var volume: Double = 1.0
    @Published var isMuted: Bool = false
    @Published var activeEQType: EqualizerType = .basic
    
    // Limits UI updates to 60fps or less if state thrashes
    private var throttleSubject = PassthroughSubject<ApplicationState, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MIDI
    private var midiManager = MIDIManager()
    
    // Sidechain
    @Published var sidechain: SidechainManager = SidechainManager()
    
    init() {
        // Subscribe to the global store
        Application.store.subscribe(self)
        
        // Setup throttling (optional, but good for high-freq updates)
        throttleSubject
            .throttle(for: .milliseconds(16), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] state in
                self?.updateLocalState(from: state)
            }
            .store(in: &cancellables)
            
        setupDefaultMappings()
    }
    
    deinit {
        Application.store.unsubscribe(self)
    }
    
    // MARK: - ReSwift Subscriber
    func newState(state: ApplicationState) {
        // Feed the throttler
        throttleSubject.send(state)
    }
    
    private var hasDoneSafetyCheck = false
    
    // MARK: - Plugin State
    @Published var activePluginName: String?
    
    func loadPlugin(_ plugin: AudioPlugin) {
        let pm = PluginManager()
        pm.loadPlugin(plugin) { [weak self] avUnit in
            guard let self = self, let avUnit = avUnit else { return }
            
            DispatchQueue.main.async {
                self.activePluginName = plugin.name
                if let engine = Application.engine {
                    engine.insertPlugin(avUnit)
                }
            }
        }
    }
    
    // MARK: - Input & Limiter State
    @Published var inputDevices: [AudioDevice] = []
    @Published var activeInputDevice: AudioDevice?
    @Published var limiterEnabled: Bool = true
    
    func refreshInputDevices() {
        if let sources = Application.engine?.sources {
            self.inputDevices = sources.getAllInputDevices()
        }
    }
    
    func selectSystemAudio() {
        if let sources = Application.engine?.sources {
            sources.setSystemDevice()
            activeInputDevice = nil // Represents System
        }
    }
    
    func selectInputDevice(_ device: AudioDevice) {
        if let sources = Application.engine?.sources {
            sources.setInputDevice(device)
            activeInputDevice = device
        }
    }
    
    func toggleLimiter() {
        limiterEnabled.toggle()
        if let engine = Application.engine {
            engine.limiter.enabled = limiterEnabled
        }
    }
    
    // MARK: - EQ State
    @Published var bassGain: Double = 0
    @Published var midGain: Double = 0
    @Published var trebleGain: Double = 0
    
    @Published var bassKilled: Bool = false
    @Published var midKilled: Bool = false
    @Published var trebleKilled: Bool = false
    
    // Storage for pre-kill values
    private var preKillBass: Double = 0
    private var preKillTreble: Double = 0
    
    func setupDefaultMappings() {
        // Defaults for standard DJ controllers
        
        // CC 1: Master Volume (0-1)
        midiManager.map(cc: 1) { [weak self] val in
            self?.setVolume(val) // Maps 0-1 to 0-1 (Unity)
        }
        
        // CC 2: Filter (0-1)
        midiManager.map(cc: 2) { [weak self] val in
            self?.setFilterValue(val)
        }
        
        // CC 3: Low (-12 to +12)
        midiManager.map(cc: 3) { [weak self] val in
            let db = (val * 24) - 12
            self?.setBandGain(.bass, value: db)
        }
        
        // CC 4: Mid
        midiManager.map(cc: 4) { [weak self] val in
            let db = (val * 24) - 12
            self?.setBandGain(.mid, value: db)
        }
        
        // CC 5: High
        midiManager.map(cc: 5) { [weak self] val in
            let db = (val * 24) - 12
            self?.setBandGain(.treble, value: db)
        }
    }
    
    private func updateLocalState(from state: ApplicationState) {
        // Update UI on Main Thread
        DispatchQueue.main.async {
            // Safety: If first load and volume is loud, cap it
            if !self.hasDoneSafetyCheck {
                self.hasDoneSafetyCheck = true
                if state.volume.gain > 0.8 {
                    self.setVolume(0.5)
                }
            }
            
            if self.isEnabled != state.enabled {
                self.isEnabled = state.enabled
            }
            
            // Map Volume
            if self.volume != state.volume.gain {
                self.volume = state.volume.gain
            }
            
            if self.isMuted != state.volume.muted {
                self.isMuted = state.volume.muted
            }
            
            // Map EQ Type
            if self.activeEQType != state.effects.equalizers.type {
                self.activeEQType = state.effects.equalizers.type
            }
            
            // Sync Basic EQ Gains (only if we are not killing them locally)
            if self.activeEQType == .basic {
                let eqState = state.effects.equalizers.basic
                if let preset = BasicEqualizer.getPreset(id: eqState.selectedPresetId) {
                    if !self.bassKilled && abs(self.bassGain - preset.gains.bass) > 0.1 {
                        self.bassGain = preset.gains.bass
                    }
                    if !self.midKilled && abs(self.midGain - preset.gains.mid) > 0.1 {
                        self.midGain = preset.gains.mid
                    }
                    if !self.trebleKilled && abs(self.trebleGain - preset.gains.treble) > 0.1 {
                        self.trebleGain = preset.gains.treble
                    }
                }
            }
        }
    }
    
    // MARK: - Actions (UI Intents)
    
    enum DJBand { case bass, mid, treble }
    
    func setBandGain(_ band: DJBand, value: Double) {
        // Update local
        switch band {
        case .bass: bassGain = value; if bassKilled { return }
        case .mid: midGain = value; if midKilled { return }
        case .treble: trebleGain = value; if trebleKilled { return }
        }
        
        // Dispatch to Engine directly for latency
        if let eq = Application.engine?.equalizers.active as? BasicEqualizer {
            switch band {
            case .bass: eq.bassGain = value
            case .mid: eq.midGain = value
            case .treble: eq.trebleGain = value
            }
        }
    }
    
    func toggleKill(_ band: DJBand) {
        // Logic: Toggle kill state and apply -24dB or restore
        if let eq = Application.engine?.equalizers.active as? BasicEqualizer {
            switch band {
            case .bass:
                bassKilled.toggle()
                eq.bassGain = bassKilled ? -24 : bassGain
            case .mid:
                midKilled.toggle()
                eq.midGain = midKilled ? -24 : midGain
            case .treble:
                trebleKilled.toggle()
                eq.trebleGain = trebleKilled ? -24 : trebleGain
            }
        }
    }
    

    func setFilterValue(_ value: Double) {
        if let engine = Application.engine {
            engine.filter.value = Float(value)
        }
    }
    
    func setVolume(_ newVolume: Double) {
        // Optimistic UI update (avoids lag)
        self.volume = newVolume
        
        // Dispatch to Store
        Application.dispatchAction(VolumeAction.setGain(newVolume, false))
    }
    
    func toggleMute() {
        let newMuteState = !isMuted
        self.isMuted = newMuteState
        Application.dispatchAction(VolumeAction.setMuted(newMuteState))
    }
    
    // MARK: - Presets State
    @Published var presets: [BasicEqualizerPreset] = []
    @Published var selectedPresetId: String?
    
    func loadPresets() {
        self.presets = BasicEqualizer.presets
    }
    
    func selectPreset(_ preset: BasicEqualizerPreset) {
        // Use the Action we know exists or infer it.
        // Based on BasicEqualizer.swift:
        // It subscribes to store. So we must Dispatch.
        // Let's try finding the Action.
        // For now, let's just update local to show selection, but we need the Store to update engine.
        
        // Placeholder for Action Dispatch:
        // Application.dispatchAction(BasicEqualizerAction.selectPreset(preset.id))
        
        // Mock implementation for UI feedback:
        selectedPresetId = preset.id
        

        // Apply gains immediately to local state variables
        self.bassGain = preset.gains.bass
        self.midGain = preset.gains.mid
        self.trebleGain = preset.gains.treble
        
        // Update Engine directly
        if let eq = Application.engine?.equalizers.active as? BasicEqualizer {
            eq.bassGain = preset.gains.bass
            eq.midGain = preset.gains.mid
            eq.trebleGain = preset.gains.treble
        }
    }
    
    func savePreset(name: String) {
        let gains = BasicEqualizerPresetGains(bass: self.bassGain, mid: self.midGain, treble: self.trebleGain)
        _ = BasicEqualizer.createPreset(name: name, peakLimiter: false, gains: gains)
        loadPresets()
    }
