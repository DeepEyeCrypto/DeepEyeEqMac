//
//  DesignSystem.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import SwiftUI

extension Color {
    struct DeepEye {
        // Deep Void: Introduction of the main background color
        static let void = Color(red: 0.04, green: 0.04, blue: 0.04) // #0A0A0A
        
        // Surface: Slightly lighter for panels
        static let surface = Color(red: 0.1, green: 0.1, blue: 0.1) // #1A1A1A
        
        // Accent: Cyber Teal
        static let accent = Color(red: 0.0, green: 0.95, blue: 1.0) // #00F3FF
        
        // Semantic: Signal states
        static let signalHot = Color.yellow
        static let signalClip = Color(red: 1.0, green: 0.0, blue: 0.33) // #FF0055
        static let signalSafe = Color(red: 0.8, green: 1.0, blue: 0.0) // #CCFF00
    }
}

extension Font {
    static var deepHeading: Font {
        .system(.title, design: .rounded).bold()
    }
    
    static var deepLabel: Font {
        .system(.caption2, design: .monospaced)
    }
    
    static var deepValue: Font {
        .system(.body, design: .monospaced).weight(.heavy)
    }
}

// MARK: - View Modifiers

struct DeepGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Material.ultraThin)
            .opacity(0.9)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

extension View {
    func deepGlass() -> some View {
        self.modifier(DeepGlassModifier())
    }
    
    func deepGlow() -> some View {
        self.shadow(color: Color.DeepEye.accent.opacity(0.6), radius: 8, x: 0, y: 0)
    }
}
