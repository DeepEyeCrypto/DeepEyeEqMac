//
//  DeepKnob.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import SwiftUI

struct DeepKnob: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0.0...1.0
    var title: String
    
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        VStack {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    .frame(width: 120, height: 120)
                
                // Value Arc
                Circle()
                    .trim(from: 0, to: CGFloat(normalizedValue))
                    .stroke(
                        LinearGradient(gradient: Gradient(colors: [.deepEyeTeal, .deepEyePurple]), startPoint: .bottomLeading, endPoint: .topTrailing),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(135)) // Start from bottom left
                    .rotationEffect(.degrees(90)) // Adjust for SwiftUI circle start (right)
                
                // Indicators inside knob?
                Text(String(format: "%.1f", value))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let dragChange = gesture.translation.height - lastDragValue
                        // Sensitivity: move 100 pixels to change full range
                        let change = Double(-dragChange / 100.0) * (range.upperBound - range.lowerBound)
                        let newValue = (value + change).clamped(to: range)
                        value = newValue
                        lastDragValue = gesture.translation.height
                    }
                    .onEnded { _ in
                        lastDragValue = 0
                    }
            )
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
    }
    
    private var normalizedValue: Double {
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound) * 0.75 // 75% circle arc
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
