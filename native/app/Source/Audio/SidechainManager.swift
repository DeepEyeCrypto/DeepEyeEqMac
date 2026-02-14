//
//  SidechainManager.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import AVFoundation
import Combine

/// Manages Microphone Ducking
class SidechainManager: ObservableObject {
    
    // Config
    @Published var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    @Published var thresholdDb: Float = -20.0
    @Published var reductionDb: Float = -12.0 // How much to cut
    @Published var attackTime: Float = 0.1
    @Published var releaseTime: Float = 1.0
    
    // Internal
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var currentGain: Float = 0.0 // 0dB
    
    init() {
        setupRecorder()
    }
    
    private func setupRecorder() {
        // Setup a simple recorder to monitor levels (no file save needed really, but API requires URL)
        let tempURL = URL(fileURLWithPath: "/dev/null")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        do {
            recorder = try AVAudioRecorder(url: tempURL, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.prepareToRecord()
        } catch {
            print("Sidechain Recorder Error: \(error)")
        }
    }
    
    func startMonitoring() {
        guard let recorder = recorder else { return }
        recorder.record()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.processLoop()
        }
    }
    
    func stopMonitoring() {
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        // Reset Gain
        setEngineGain(0)
    }
    

    private func processLoop() {
        guard let recorder = recorder else { return }
        recorder.updateMeters()
        
        let power = recorder.averagePower(forChannel: 0)
        
        // Logic: Simple Knee
        var targetGainDb: Float = 0.0
        
        if power > thresholdDb {
            targetGainDb = reductionDb
        }
        
        // One-Pole Filter Smoothing
        // y[n] = y[n-1] + alpha * (x[n] - y[n-1])
        let isAttacking = targetGainDb < currentGain
        let tau = isAttacking ? max(attackTime, 0.01) : max(releaseTime, 0.01)
        let dt: Float = 0.05
        let alpha = dt / (tau + dt)
        
        currentGain = currentGain + (targetGainDb - currentGain) * alpha
        
        setEngineGain(currentGain)
    }
    
    private func setEngineGain(_ db: Float) {
        if let engine = Application.engine {
            engine.sidechainNode.globalGain = db
        }
    }
}
