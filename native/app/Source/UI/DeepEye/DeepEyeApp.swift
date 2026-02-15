//
//  DeepEyeApp.swift
//  eqMac
//
//  Created by DeepEye AI on 2026.
//

import SwiftUI
import SwiftyUserDefaults
import EmitterKit

@main
struct DeepEyeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // We can inject the AppModel here
    @StateObject var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            DeepEyeRoot()
                .environmentObject(appModel)
                .frame(minWidth: 400, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // Add custom menu commands here
             CommandGroup(replacing: .newItem) { }
        }
    }
}
