//
//  DeepKnob.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import SwiftUI

struct DeepKnob: View {
    @Binding var value: Double

    var range: ClosedRange<Double> = 0...1
    var title: String = "VOL"
    var showCenterDetent: Bool = false
    
    // Constants
    private let size: CGFloat = 80
    private let trackWidth: CGFloat = 8
    private let sensitivity: Double = 0.005 // Units per pixel
    
    // Interaction State
    @State private var dragStartValue: Double = 0
    @State private var isDragging: Bool = false
    

    
    private var normalizedValue: Double {
        let n = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return min(max(n, 0), 1)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background Track (Arc 270 degrees: -135 to +135)
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.DeepEye.surface, style: StrokeStyle(lineWidth: trackWidth, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .frame(width: size, height: size)
                
                // Active Value Arc
                Circle()
                    .trim(from: 0, to: CGFloat(normalizedValue * 0.75))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.DeepEye.accent.opacity(0.3), .DeepEye.accent]),
                            center: .center,
                            startAngle: .degrees(135),
                            endAngle: .degrees(135 + (normalizedValue * 270))
                        ),
                        style: StrokeStyle(lineWidth: trackWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .frame(width: size, height: size)

                    .deepGlow()
                
                // Center Detent
                if showCenterDetent {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2, height: 6)
                        .offset(y: -size/2 + 3)
                }
                
                // Value Display
                VStack(spacing: 0) {
                    if isDragging {
                        Text(String(format: "%.1f", value)) // Show raw value when dragging
                            .font(.deepValue)
                            .foregroundColor(.DeepEye.accent)
                    } else {
                        Text("\(Int(normalizedValue * 100))%")
                            .font(.deepValue)
                            .foregroundColor(.white)
                    }
                }
            }
            // Invisible Hit Area + Gesture
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            dragStartValue = value
                        }
                        
                        // Vertical Drag Logic: Drag Up = Increase
                        let delta = Double(-gesture.translation.height) * sensitivity * (range.upperBound - range.lowerBound)
                        
                        // Clamp new value
                        let newValue = min(max(dragStartValue + delta, range.lowerBound), range.upperBound)
                        
                        // Haptic feedback on limits? (Optional)
                        if newValue != value {
                            // UI Update
                            self.value = newValue
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            
            Text(title)
                .font(.deepLabel)
                .foregroundColor(isDragging ? .DeepEye.accent : .gray)
        }
    }
}

struct DeepKnob_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.DeepEye.void.edgesIgnoringSafeArea(.all)
            DeepKnob(value: .constant(0.75), title: "GAIN")
        }
    }
}
