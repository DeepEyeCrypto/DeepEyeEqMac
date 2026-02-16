//
//  SpectrumProvider.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import SwiftUI
import Combine

import Accelerate

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
        
        // Read latest samples from CircularBuffer
        // We need fftSize samples.
        // CircularBuffer.read(into: ...) requires an AudioBufferList structure.
        
        // Prepare ABL
        var audioBuffer = AudioBuffer(
            mNumberChannels: 1, // Mono FFT for simplicity
            mDataByteSize: UInt32(fftSize * MemoryLayout<Float>.size),
            mData: UnsafeMutableRawPointer.allocate(byteCount: fftSize * MemoryLayout<Float>.size, alignment: MemoryLayout<Float>.alignment)
        )
        var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: (audioBuffer))
        
        let lastSampleTime = Int64(engine.lastSampleTime)
        // Read 1024 frames ending at lastSampleTime
        let startRead = max(0, lastSampleTime - Int64(fftSize))
        
        let err = engine.buffer.read(into: &bufferList, from: startRead, to: lastSampleTime)
        
        if err == .noError {
            // Process data
            if let ptr = audioBuffer.mData?.assumingMemoryBound(to: Float.self) {
                 var timeDomainBuffer = Array(UnsafeBufferPointer(start: ptr, count: fftSize))
                 performFFT(&timeDomainBuffer)
            }
        }
        
        // Cleanup
        audioBuffer.mData?.deallocate()
    }
    
    private func performFFT(_ data: inout [Float]) {
         // Windowing
         vDSP_vmul(data, 1, window, 1, &data, 1, vDSP_Length(fftSize))
         
         // Setup split complex buffer
         var real = [Float](repeating: 0, count: fftSize/2)
         var imag = [Float](repeating: 0, count: fftSize/2)
         var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)
         
         // Pack data: As we are doing Real FFT, we treat input as even/odd points? 
         // Actually vDSP_ctoz converts interleaved complex to split complex. 
         // But for Real input, we can cast [Float] to UnsafePointer<DSPComplex> if stride is 2.
         // Easier: vDSP_fft_zrip takes split complex where input is modified in place.
         
         // Copy data to split complex format (Interleaved -> Split)
         // Treat input as Real data. We use vDSP_ctoz on the data casted.
         data.withUnsafeBufferPointer { bufferPtr in
             bufferPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize/2) { complexPtr in
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
         
         // Map to Bands (30 bars)
         // Simple linear averaging or log mapping. Log is better for audio.
         // For 'DeepEye' MVP, let's do a simple downsampling.
         
         var bars: [CGFloat] = []
         let bandWidth = (fftSize / 2) / 30
         
         for i in 0..<30 {
             let start = i * bandWidth
             let end = start + bandWidth
             let slice = normalizedMags[start..<end]
             let sum = slice.reduce(0, +)
             let avg = sum / Float(slice.count)
             
             // Log scale for height
             let db = 10 * log10(avg + 0.0001) // avoid log(0)
             // Map dB (-60...0) to 0...1
             let normalizedHeight = CGFloat(max(0, (db + 60) / 60))
             bars.append(normalizedHeight)
         }
         
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
