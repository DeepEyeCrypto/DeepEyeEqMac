//
//  SpectrumProvider.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import SwiftUI
import Combine

class SpectrumModel: ObservableObject {
    @Published var amplitudes: [CGFloat] = Array(repeating: 0.1, count: 30)
    
    private var timer: Timer?
    
    init() {
        startSimulation()
    }
    
    func startSimulation() {
        // Placeholder simulation until real FFT is hooked up
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            var newAmps: [CGFloat] = []
            for _ in 0..<30 {
                newAmps.append(CGFloat.random(in: 0.1...0.8))
            }
            DispatchQueue.main.async {
                self.amplitudes = newAmps
            }
        }
    }
    
    deinit {
        timer?.invalidate()
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
