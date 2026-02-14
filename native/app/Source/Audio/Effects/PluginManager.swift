//
//  PluginManager.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import AVFoundation
import AudioToolbox

struct AudioPlugin: Identifiable, Hashable {
    let id: String
    let name: String
    let manufacturer: String
    let componentDescription: AudioComponentDescription
    
    // Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AudioPlugin, rhs: AudioPlugin) -> Bool {
        return lhs.id == rhs.id
    }
}

class PluginManager: ObservableObject {
    @Published var availablePlugins: [AudioPlugin] = []
    
    init() {
        scanPlugins()
    }
    
    func scanPlugins() {
        DispatchQueue.global(qos: .userInitiated).async {
            var plugins: [AudioPlugin] = []
            
            // Search for Audio Units (Effects)
            var desc = AudioComponentDescription()
            desc.componentType = kAudioUnitType_Effect
            desc.componentSubType = 0
            desc.componentManufacturer = 0
            desc.componentFlags = 0
            desc.componentFlagsMask = 0
            
            var comp: AudioComponent? = nil
            
            while true {
                comp = AudioComponentFindNext(comp, &desc)
                guard let validComp = comp else { break }
                
                var name: Unmanaged<CFString>?
                AudioComponentCopyName(validComp, &name)
                
                if let nameStr = name?.takeRetainedValue() as String? {
                    let parts = nameStr.components(separatedBy: ": ")
                    let manufacturer = parts.count > 1 ? parts.first! : "Apple"
                    let pluginName = parts.last ?? nameStr
                    
                    var actualDesc = AudioComponentDescription()
                    AudioComponentGetDescription(validComp, &actualDesc)
                    
                    let plugin = AudioPlugin(
                        id: "\(manufacturer).\(pluginName)",
                        name: pluginName,
                        manufacturer: manufacturer,
                        componentDescription: actualDesc
                    )
                    plugins.append(plugin)
                }
            }
            
            DispatchQueue.main.async {
                self.availablePlugins = plugins.sorted { $0.name < $1.name }
            }
        }
    }

    
    // Instantiation helper
    func loadPlugin(_ plugin: AudioPlugin, completion: @escaping (AVAudioUnit?) -> Void) {
        AVAudioUnit.instantiate(with: plugin.componentDescription, options: .loadOutOfProcess) { avUnit, error in
            if let error = error {
                print("Failed to load plugin: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(avUnit)
        }
    }
}
