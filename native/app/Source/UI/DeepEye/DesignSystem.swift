//
//  DesignSystem.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import SwiftUI

extension Color {
    static let deepEyeTeal = Color(red: 0.0, green: 0.898, blue: 1.0) // #00E5FF
    static let deepEyePurple = Color(red: 0.835, green: 0.0, blue: 0.976) // #D500F9
    static let deepEyeBg = Color(red: 0.07, green: 0.07, blue: 0.07) // #121212
    static let deepEyeDarkBg = Color(red: 0.12, green: 0.12, blue: 0.12) // #1E1E1E
}

struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.deepEyeDarkBg)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
