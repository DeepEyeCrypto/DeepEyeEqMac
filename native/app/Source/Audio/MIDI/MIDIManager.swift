//
//  MIDIManager.swift
//  DeepEyeEqMac
//
//  Created by [Agent] on 2024.
//

import Foundation
import CoreMIDI
import Combine

class MIDIManager: ObservableObject {
    var midiClient = MIDIClientRef()
    var inputPort = MIDIPortRef()
    
    // Mapping: CC Number -> Callback (Value 0.0-1.0)
    var ccMappings: [UInt8: (Double) -> Void] = [:]
    
    @Published var lastCC: UInt8?
    @Published var lastValue: UInt8?
    
    init() {
        setupMIDI()
    }
    
    func setupMIDI() {
        var status = MIDIClientCreate("DeepEyeClient" as CFString, nil, nil, &midiClient)
        if status != noErr {
            print("Error creating MIDI client: \(status)")
            return
        }
        
        // callback closure
        let notifyBlock: MIDIReadBlock = { [weak self] packetList, _ in
            guard let self = self else { return }
            self.parse(packetList)
        }
        
        status = MIDIInputPortCreateWithBlock(midiClient, "DeepEyeInput" as CFString, &inputPort, notifyBlock)
        if status != noErr {
            print("Error creating MIDI input port: \(status)")
            return
        }
        
        connectSources()
    }
    
    func connectSources() {
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let src = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, src, nil)
        }
    }
    
    private func parse(_ packetList: UnsafePointer<MIDIPacketList>) {
        let packets = packetList.pointee
        let packet = packets.packet
        
        // Access payload safely
        var dataTuple = packet.data
        withUnsafeBytes(of: &dataTuple) { ptr in
            // Basic check: length
            let length = Int(packet.length)
            guard length >= 3 else { return }
            
            // Extract bytes
            let status = ptr[0]
            if (status & 0xF0) == 0xB0 { // Control Change on any channel
                let cc = ptr[1]
                let val = ptr[2]
                handleCC(cc, value: val)
            }
        }
    }
    
    private func handleCC(_ cc: UInt8, value: UInt8) {
        DispatchQueue.main.async {
            self.lastCC = cc
            self.lastValue = value
            
            // Normalize 0-127 -> 0.0-1.0
            let normalized = Double(value) / 127.0
            
            // Execute callback
            if let callback = self.ccMappings[cc] {
                callback(normalized)
            }
        }
    }
    
    // Mapping API
    func map(cc: UInt8, to action: @escaping (Double) -> Void) {
        ccMappings[cc] = action
    }
}
