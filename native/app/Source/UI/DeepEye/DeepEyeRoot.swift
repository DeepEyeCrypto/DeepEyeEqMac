//
//  DeepEyeRoot.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import SwiftUI

struct DeepEyeRoot: View {
    @EnvironmentObject var appModel: AppModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DeepEye")
                    .font(.custom("Modern-Bold", size: 18))
                    .foregroundColor(Color("DeepEyeTeal"))
                Spacer()
                Button(action: {
                    // Settings
                }) {
                    Image(systemName: "gear")
                }
            }
            .padding()
            .background(Color("DeepEyeDarkBg"))
            
            // Main Content Area
            ZStack {
                if appModel.isLoading {
                    ProgressView("Initializing Engine...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Volume Boost")
                            // Placeholder for Volume Knob
                            Circle()
                                .stroke(Color.gray, lineWidth: 3)
                                .frame(width: 150, height: 150)
                            
                            Text("Equalizer")
                            // Placeholder for EQ
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 100)
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
        .background(Color("DeepEyeBg"))
    }
}
