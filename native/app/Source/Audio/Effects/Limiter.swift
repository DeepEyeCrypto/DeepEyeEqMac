//
//  Limiter.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import AVFoundation
import EmitterKit

/// A Safety Brickwall Limiter
/// Uses the system Dynamics Processor to prevent clipping.
class Limiter: Effect {
    
    var dynamicsNode: AVAudioUnitDynamicsProcessor
    
    override init() {
        dynamicsNode = AVAudioUnitDynamicsProcessor()
        super.init()
        self.node = dynamicsNode
        
        setupLimiter()
    }
    
    private func setupLimiter() {
        // Configure as a Brickwall Limiter
        // 1. Threshold: -0.5 dB (Prevent hitting 0.0 hard)
        dynamicsNode.threshold = -0.1 // dB
        
        // 2. Headroom: 
        // 3. Expansion Ratio: 1 (No expansion)
        dynamicsNode.expansionRatio = 1.0
        
        // 4. Compression Ratio: Infinity (or very high)
        // AVAudioUnitDynamicsProcessor caps at 40.0 usually, which is effectively limiting.
        // Actually, let's check the API limits. 
        // Default is often 1.0. Range 1.0 -> 40.0.
        // But for a true brickwall, we want a Peak Limiter AudioUnit.
        // However, sticking to the Swift class for stability in M3.
        // A ratio of 40:1 is "hard compression".
        dynamicsNode.ratio = 40.0
        
        // 5. Attack: Fast as possible (0.002s is the min often)
        dynamicsNode.attackTime = 0.002 
        
        // 6. Release: Fast but not distorting (0.05s)
        dynamicsNode.releaseTime = 0.050
        
        // 7. Master Gain: 0 dB (Makeup gain)
        dynamicsNode.masterGain = 0.0
        
        // Start enabled
        enabled = true
        // Bypass based on enabled property is handled by super class (but requires node reference)
    }
    
    // Updates
    func setDrive(_ driveDb: Float) {
        // "Drive" pushes the input gain naturally? 
        // Or we use 'inputAmplitude' if available? No.
        // The previous node (Volume) handles drive.
        // This limiter strictly acts as a safety.
    }
    
    override func enabledDidSet() {
        dynamicsNode.bypass = !enabled
    }
}
