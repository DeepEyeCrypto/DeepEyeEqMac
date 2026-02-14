//
//  PluginSelector.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import SwiftUI
import AVFoundation

struct PluginSelector: View {
    @ObservedObject var appModel: AppModel
    
    // Local Plugin Manager
    @StateObject private var pluginManager = PluginManager()
    @State private var showingBrowser = false
    
    var body: some View {
        Button(action: {
            showingBrowser = true
        }) {
                    VStack {
                        if let name = appModel.activePluginName {
                            Text(name)
                                .font(.caption2)
                                .foregroundColor(.DeepEye.accent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text("FX")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    }
            .frame(width: 50, height: 30)
            .background(Color.DeepEye.surface)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(appModel.activePluginName != nil ? Color.DeepEye.accent : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingBrowser) {
            PluginBrowser(pluginManager: pluginManager) { selectedPlugin in
                appModel.loadPlugin(selectedPlugin)
                showingBrowser = false
            }
        }
    }
}

struct PluginBrowser: View {
    @ObservedObject var pluginManager: PluginManager
    var onSelect: (AudioPlugin) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(pluginManager.availablePlugins) { plugin in
                Button(action: {
                    onSelect(plugin)
                }) {
                    VStack(alignment: .leading) {
                        Text(plugin.name)
                            .font(.headline)
                        Text(plugin.manufacturer)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Select Plugin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
