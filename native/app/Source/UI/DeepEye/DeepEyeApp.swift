//
//  DeepEyeApp.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import SwiftUI

// FUTURE MIGRATION NOTE:
// Once the legacy C++ bridge (Application.h/m) and AppDelegate are removed,
// uncomment the @main struct below to make this the pure entry point.

/*
@main
struct DeepEyeApp: App {
    // Connect to AppModel (State)
    @StateObject private var appModel = AppModel()

    init() {
        // Initialize Core Audio Engine here if AppDelegate is gone
        // Application.start() 
    }

    var body: some Scene {
        WindowGroup {
            DeepEyeRoot()
                .environmentObject(appModel)
                .onAppear {
                    // Prevent window from being standard macOS size
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
*/

// Current Bridge (Used by Application.swift):
// logic is handled in Application.showDeepEye()
