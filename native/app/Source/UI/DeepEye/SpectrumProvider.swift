//
//  SpectrumProvider.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import SwiftUI
import Combine

import Accelerate
import AudioToolbox

class SpectrumModel: ObservableObject {
    @Published var amplitudes: [CGFloat] = Array(repeating: 0.1, count: 30)
    
    private let fftSize = 1024
    private lazy var log2n = vDSP_Length(log2(Float(fftSize)))
    private lazy var fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
    
    // Buffers
    private var window: [Float] = []
    
    // Concurrency
    private let processingQueue = DispatchQueue(label: "com.deepeye.audio.fft", qos: .userInteractive)
    private var dispatchTimer: DispatchSourceTimer?
    
    init() {
        setupWindow()
        startProcessing()
    }
    
    private func setupWindow() {
        window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }
    
    func startProcessing() {
        // Create timer on background queue
        dispatchTimer = DispatchSource.makeTimerSource(flags: [], queue: processingQueue)
        dispatchTimer?.schedule(deadline: .now(), repeating: .milliseconds(33)) // ~30fps
        
        dispatchTimer?.setEventHandler { [weak self] in
            self?.processAudio()
        }
        
        dispatchTimer?.resume()
    }
    
    private func processAudio() {
        // Ensure engine exists (thread-safe check?)
        // Application.engine is a global static, usually safe to read pointer but modify is dangerous.
        // We only read.
        guard let engine = Application.engine else { return }

        let lastSampleTime = Int64(engine.lastSampleTime)
        guard lastSampleTime > 0 else { return }
        
        // Read latest samples from CircularBuffer
        // We need fftSize samples.
        // CircularBuffer.read(into: ...) requires an AudioBufferList structure.

        // Read 1024 frames ending at lastSampleTime
        let startRead = max(0, lastSampleTime - Int64(fftSize))

        // Prepare mono buffer for FFT input
        var timeDomainBuffer = [Float](repeating: 0, count: fftSize)
        timeDomainBuffer.withUnsafeMutableBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }

            var audioBuffer = AudioBuffer(
                mNumberChannels: 1,
                mDataByteSize: UInt32(rawBuffer.count),
                mData: baseAddress
            )
            var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: audioBuffer)

            let err = engine.buffer.read(into: &bufferList, from: startRead, to: lastSampleTime)
            guard err == .noError else { return }

            performFFT(&timeDomainBuffer)
        }
    }
    
    private func performFFT(_ data: inout [Float]) {
         // Windowing
         vDSP_vmul(data, 1, window, 1, &data, 1, vDSP_Length(fftSize))

         // Setup split complex buffer
         var real = [Float](repeating: 0, count: fftSize/2)
         var imag = [Float](repeating: 0, count: fftSize/2)
         var bars: [CGFloat] = []

         real.withUnsafeMutableBufferPointer { realBuffer in
             imag.withUnsafeMutableBufferPointer { imagBuffer in
                 guard let realPtr = realBuffer.baseAddress,
                       let imagPtr = imagBuffer.baseAddress else { return }

                 var splitComplex = DSPSplitComplex(realp: realPtr, imagp: imagPtr)

                 // Pack data (interleaved complex) into split-complex format.
                 data.withUnsafeBufferPointer { bufferPtr in
                     guard let baseAddress = bufferPtr.baseAddress else { return }
                     baseAddress.withMemoryRebound(to: DSPComplex.self, capacity: fftSize/2) { complexPtr in
                         vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftSize/2))
                     }
                 }

                 // FFT
                 vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

                 // Magnitude
                 var magnitudes = [Float](repeating: 0.0, count: fftSize/2)
                 vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize/2))

                 // Normalize
                 var normalizedMags = [Float](repeating: 0.0, count: fftSize/2)
                 var multiplier = Float(1.0 / Float(fftSize))
                 vDSP_vsmul(magnitudes, 1, &multiplier, &normalizedMags, 1, vDSP_Length(fftSize/2))

                 // Map to 30 visual bands.
                 let bandCount = 30
                 let bandWidth = max(1, (fftSize / 2) / bandCount)
                 bars.reserveCapacity(bandCount)

                 for i in 0..<bandCount {
                     let start = i * bandWidth
                     let end = min(start + bandWidth, normalizedMags.count)
                     guard start < end else {
                         bars.append(0)
                         continue
                     }

                     let slice = normalizedMags[start..<end]
                     let avg = slice.reduce(0, +) / Float(slice.count)

                     // Log scale for height; map dB (-60...0) to 0...1.
                     let db = 10.0 * log10(avg + 0.0001)
                     let normalizedHeight = CGFloat(max(0.0, (db + 60.0) / 60.0))
                     bars.append(normalizedHeight)
                 }
             }
         }

         guard !bars.isEmpty else { return }
         DispatchQueue.main.async {
             self.amplitudes = bars
         }
    }
    
    deinit {
        dispatchTimer?.cancel()
        vDSP_destroy_fftsetup(fftSetup)
    }
}

struct SpectrumView: View {
    @ObservedObject var model = SpectrumModel()
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<model.amplitudes.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(gradient: Gradient(colors: [.deepEyePurple, .deepEyeTeal]), startPoint: .bottom, endPoint: .top))
                    .frame(height: model.amplitudes[index] * 100)
                    .animation(.easeInOut(duration: 0.05), value: model.amplitudes[index])
            }
        }
        .frame(height: 100)
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}
