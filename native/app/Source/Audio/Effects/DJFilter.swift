//
//  DJFilter.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import AVFoundation
import EmitterKit

/// A Combined DJ Filter Effect (Low Pass / High Pass)
/// Behavior:
/// - Knob Center (0.5 or 0.0 depending on range): Bypass
/// - Knob Left (< 0.5): Low Pass Filter (Cutoff drops)
/// - Knob Right (> 0.5): High Pass Filter (Cutoff rises)
class DJFilter: Effect {
    
    // Using AVAudioUnitEQ for the filter implementation
    var eqUnit: AVAudioUnitEQ
    
    // Filter parameter range: 0.0 (Full LPF) to 1.0 (Full HPF). 0.5 is Neutral.
    var value: Float = 0.5 {
        didSet {
            updateFilter()
        }
    }
    
    // Resonance (Q)
    var resonance: Float = 0.5 // Default resonance
    
    override init() {
        // Create unit
        eqUnit = AVAudioUnitEQ(numberOfBands: 1)
        super.init()
        self.node = eqUnit
        
        // Initialize as neutral
        updateFilter()
    }
    
    private func updateFilter() {
        let band = eqUnit.bands[0]
        band.bypass = false
        
        // Neutral Zone (Deadband around 0.5)
        if value > 0.48 && value < 0.52 {
            band.bypass = true
            return
        }
        
        if value < 0.5 {
            // LOW PASS MODE (0.0 to 0.5)
            // Map 0.0 -> 0.5 to Frequency 20Hz -> 20kHz (Logarithmic)
            // But usually DJ filters work: 
            // 0.5 (Neutral) -> 20kHz
            // 0.0 (Full Cut) -> 100Hz
            band.filterType = .lowPass
            
            // Map 0.0...0.5 to 100...20000 exponentially
            // Normalized input (0.0...1.0) where 1.0 is neutral for LPF logic
            let normalized = value * 2.0 // 0.0 to 1.0
            let minFreq: Float = 100.0
            let maxFreq: Float = 20000.0
            
            // Exponential mapping: f = min * (max/min)^n
            let frequency = minFreq * pow((maxFreq / minFreq), normalized)
            band.frequency = frequency
            
        } else {
            // HIGH PASS MODE (0.5 to 1.0)
            // 0.5 (Neutral) -> 20Hz (All pass)
            // 1.0 (Full Cut) -> 20kHz (High Pass)
            band.filterType = .highPass
            
            // Normalized input (0.0...1.0)
            let normalized = (value - 0.5) * 2.0
            let minFreq: Float = 20.0
            let maxFreq: Float = 18000.0 // Don't cut absolutely everything
            
            // Exponential mapping
            let frequency = minFreq * pow((maxFreq / minFreq), normalized)
            band.frequency = frequency
        }
        
        // Apply Resonance
        // Map 0...1 to 0.1...10?
        band.bandwidth = 2.0 // Wide Q for smooth mixing, can be tighter
    }
    
    // Helper to toggle Effect base class behavior
    override func enabledDidSet() {
        eqUnit.bypass = !enabled
    }
}
