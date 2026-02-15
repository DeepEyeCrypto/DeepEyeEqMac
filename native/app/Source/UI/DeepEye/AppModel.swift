//
//  AppModel.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import Foundation
import SwiftUI
import Combine

class AppModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var statusMessage: String = "Ready"
    
    init() {
        // Listen for Application events
        setupListeners()
        
        // Simulate initialization delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
        }
    }
    
    private func setupListeners() {
        // Bind to Application.enabled logic etc.
    }
}
