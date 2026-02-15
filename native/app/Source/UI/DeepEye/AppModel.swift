//
//  AppModel.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

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
    
    @Published var pluginManager = PluginManager()
    @Published var activePluginName: String? = nil
    
    private func setupListeners() {
        // Bind to Application.enabled logic etc.
    }
    
    func loadPlugin(_ plugin: AudioPlugin) {
        statusMessage = "Loading \(plugin.name)..."
        pluginManager.loadPlugin(plugin) { [weak self] avUnit in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let avUnit = avUnit else {
                    self.statusMessage = "Failed to load \(plugin.name)"
                    return
                }
                
                // Insert into Engine
                if let engine = Application.engine {
                    engine.insertPlugin(avUnit)
                    self.activePluginName = plugin.name
                    self.statusMessage = "Loaded \(plugin.name)"
                } else {
                    self.statusMessage = "Engine not ready"
                }
            }
        }
    }
    
    func removePlugin() {
        if let engine = Application.engine {
            engine.removePlugin()
            self.activePluginName = nil
            self.statusMessage = "Plugin removed"
        }
    }
}
