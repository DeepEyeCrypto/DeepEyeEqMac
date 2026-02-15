//
//  DeepEyeRoot.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import SwiftUI

struct DeepEyeRoot: View {
    @EnvironmentObject var appModel: AppModel
    @State private var showingPluginSelector = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DeepEye")
                    .font(.custom("Modern-Bold", size: 18))
                    .foregroundColor(.deepEyeTeal) // Colors from DesignSystem
                Spacer()
                Button(action: {
                    showingPluginSelector = true
                }) {
                    Image(systemName: "dial.max")
                        .foregroundColor(appModel.activePluginName != nil ? .blue : .gray)
                }
                .popover(isPresented: $showingPluginSelector) {
                    PluginSelector(appModel: appModel, isPresented: $showingPluginSelector)
                }
                
                Button(action: {
                    // Settings
                }) {
                    Image(systemName: "gear")
                }
            }
            .padding()
            .background(Color.deepEyeDarkBg)
            
            // Main Content Area
            ZStack {
                if appModel.isLoading {
                    ProgressView("Initializing Engine...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Visualization
                            SpectrumView()
                                .frame(height: 120)
                                .padding(.horizontal)
                            
                            // Volume & Filter
                            HStack(spacing: 40) {
                                DeepKnob(value: $appModel.volume, title: "Volume")
                                DeepKnob(value: $appModel.filter, title: "Filter")
                            }
                            .padding()
                            
                            Divider().background(Color.gray)
                            
                            // 3-Band EQ
                            HStack(spacing: 30) {
                                DeepKnob(value: $appModel.bass, title: "Bass")
                                DeepKnob(value: $appModel.mid, title: "Mid")
                                DeepKnob(value: $appModel.treble, title: "Treble")
                            }
                            .padding()
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Footer
            HStack {
                Text(appModel.statusMessage)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(10)
        }
        .background(Color.deepEyeBg)
    }
}
