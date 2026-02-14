//
//  SpectrumProvider.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import Foundation
import Accelerate
import Combine
import CoreAudio
import Shared

class SpectrumProvider: ObservableObject {
    @Published var magnitudes: [Float] = []
    

    private let fftSize: Int = 2048
    private var log2n: vDSP_Length
    private var fftSetup: FFTSetup?
    
    private var window: [Float]
    private var realp: [Float]
    private var imagp: [Float]
    
    // Timer
    private var timer: Timer?
    
    init() {
        self.log2n = vDSP_Length(log2(Float(fftSize)))
        self.fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        
        self.window = [Float](repeating: 0, count: fftSize)
        // Split complex buffers are half size
        self.realp = [Float](repeating: 0, count: fftSize/2)
        self.imagp = [Float](repeating: 0, count: fftSize/2)
        
        // Create Blackman window
        vDSP_blkman_window(&window, vDSP_Length(fftSize), 0)
        
        start()
    }
    
    deinit {
        timer?.invalidate()
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
    
    func start() {
        // Run at ~30 FPS for now to save CPU (0.033s)
        timer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
            self?.process()
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
    

    private func process() {
        guard let engine = Application.engine, let setup = fftSetup else { return }
        
        let endFrame = Int64(engine.lastSampleTime)
        let startFrame = endFrame - Int64(fftSize)
        guard startFrame > 0 else { return }
        
        // 1. Read input signal
        var inputSignal = [Float](repeating: 0, count: fftSize)
        
        inputSignal.withUnsafeMutableBufferPointer { bufferPtr in
            guard let ptr = bufferPtr.baseAddress else { return }
            
            var buffer = AudioBuffer(
                mNumberChannels: 1,
                mDataByteSize: UInt32(fftSize * MemoryLayout<Float>.size),
                mData: ptr
            )
            
            var abl = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: (buffer)
            )
            
            _ = engine.buffer.read(into: &abl, from: startFrame, to: endFrame)
        }
        
        // 2. Windowing
        vDSP_vmul(inputSignal, 1, window, 1, &inputSignal, 1, vDSP_Length(fftSize))
        
        // 3. Pack & FFT
        inputSignal.withUnsafeBytes { ptr in
            let complexPtr = ptr.bindMemory(to: DSPComplex.self)
            guard let baseAddress = complexPtr.baseAddress else { return }
            
            realp.withUnsafeMutableBufferPointer { realPtr in
                imagp.withUnsafeMutableBufferPointer { imagPtr in
                    guard let realBase = realPtr.baseAddress, let imagBase = imagPtr.baseAddress else { return }
                    
                    var splitComplex = DSPSplitComplex(realp: realBase, imagp: imagBase)
                    
                    // Interpret Real Input as Interleaved Complex for packing
                    vDSP_ctoz(baseAddress, 2, &splitComplex, 1, vDSP_Length(fftSize/2))
                    
                    // 4. Perform Real FFT
                    vDSP_fft_zrip(setup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                    
                    // 5. Magnitudes (Squares)
                    var magSquared = [Float](repeating: 0.0, count: fftSize/2)
                    vDSP_zvmags(&splitComplex, 1, &magSquared, 1, vDSP_Length(fftSize/2))
                    
                    // 6. Map to Bars (Log Scale)
                    var visualBars: [Float] = []
                    let barCount = 64
                    
                    // Logarithmic mapping logic
                    // We want more bars for bass/mids.
                    // Simple Linear Distribution for now to verify data
                    let binSize = (fftSize/2) / barCount
                    
                    for i in 0..<barCount {
                        let start = i * binSize
                        let end = start + binSize
                        let slice = magSquared[start..<end]
                        let avgPower = slice.reduce(0, +) / Float(binSize)
                        
                        let db = 10 * log10(avgPower + 1e-9)
                        let normalized = max(0, (db + 50) / 50) // -50dB floor
                        
                        visualBars.append(normalized)
                    }
                    
                    DispatchQueue.main.async {
                        self.magnitudes = visualBars
                    }
                }
            }
        }
    }
}
