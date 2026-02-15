//
//  PluginSelector.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import SwiftUI

struct PluginSelector: View {
    @ObservedObject var appModel: AppModel
    @ObservedObject var pluginManager: PluginManager
    @Binding var isPresented: Bool
    
    init(appModel: AppModel, isPresented: Binding<Bool>) {
        self.appModel = appModel
        self.pluginManager = appModel.pluginManager
        self._isPresented = isPresented
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Select Effect Plugin")
                    .font(.headline)
                Spacer()
                Button("Close") {
                    isPresented = false
                }
            }
            .padding()
            List(pluginManager.availablePlugins) { plugin in
                Button(action: {
                    appModel.loadPlugin(plugin)
                    isPresented = false
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(plugin.name)
                                .fontWeight(.medium)
                        Text(plugin.manufacturer)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        if appModel.activePluginName == plugin.name {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(PlainListStyle())
            
            if appModel.activePluginName != nil {
                Button("Remove Active Plugin") {
                    appModel.removePlugin()
                    isPresented = false
                }
                .padding()
                .foregroundColor(.red)
            }
        }
        .frame(width: 300, height: 400)
        .background(Color("DeepEyeDarkBg"))
    }
}
