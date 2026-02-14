//
//  Engine.swift
//  eqMac
//
//  Created by Roman Kisil on 10/01/2018.
//  Copyright © 2018 Roman Kisil. All rights reserved.
//

import Cocoa
import AMCoreAudio
//import EventKit
import AVFoundation
import Foundation
import AudioToolbox
import EmitterKit
import Shared

class Engine {

  let engine: AVAudioEngine
  let sources: Sources
  let equalizers: Equalizers
  let format: AVAudioFormat


  var lastSampleTime: Double = -1
  var buffer: CircularBuffer<Float>
  let filter: DJFilter
  let limiter: Limiter
  let sidechainNode: AVAudioUnitEQ
  
  init () {
    Console.log("Creating Engine")
    engine = AVAudioEngine()
    sources = Sources()
    equalizers = Equalizers()
    filter = DJFilter()
    limiter = Limiter()
    
    sidechainNode = AVAudioUnitEQ(numberOfBands: 0)
    sidechainNode.globalGain = 0

    // Sink audio into void
    engine.mainMixerNode.outputVolume = 0

    // Setup Buffer
    let framesPerSample = Driver.device!.bufferFrameSize(direction: .playback)
    buffer = CircularBuffer<Float>(channelCount: 2, capacity: Int(framesPerSample) * 2048)

    // Attach Source
    engine.setInputDevice(sources.system.device)
    format = engine.inputNode.inputFormat(forBus: 0)
    Console.log("Set Input Engine format to: \(format.description)")

    // Attach Effects
    engine.attach(equalizers.active!.eq)
    engine.attach(filter.node)
    engine.attach(sidechainNode)
    engine.attach(limiter.node)

    // Chain: Input -> EQ -> Filter -> Sidechain -> Limiter -> Mixer
    engine.connect(engine.inputNode, to: equalizers.active!.eq, format: format)
    engine.connect(equalizers.active!.eq, to: filter.node, format: format)
    engine.connect(filter.node, to: sidechainNode, format: format)
    engine.connect(sidechainNode, to: limiter.node, format: format)
    engine.connect(limiter.node, to: engine.mainMixerNode, format: format)

    // Render callback attached to Limiter (Last Node)
    // Visualization is post-processing
    if let lastAVUnit = limiter.node as? AVAudioUnit {
        if let err = checkErr(AudioUnitAddRenderNotify(lastAVUnit.audioUnit,
                                                       renderCallback,
                                                       nil)) {
          Console.log(err)
          return
        }
    }

    // Start Engine

    engine.prepare()
    Console.log(engine)
    try! engine.start()
  }

  let renderCallback: AURenderCallback = {
    (inRefCon: UnsafeMutableRawPointer,
     ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
     inTimeStamp:  UnsafePointer<AudioTimeStamp>,
     inBusNumber: UInt32,
     inNumberFrames: UInt32,
     ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus in

    if ioActionFlags.pointee == AudioUnitRenderActionFlags.unitRenderAction_PostRender {
      if Application.engine == nil { return noErr }

      let sampleTime = inTimeStamp.pointee.mSampleTime

      let start = sampleTime.int64Value
      let end = start + Int64(inNumberFrames)
      if Application.engine?.buffer.write(from: ioData!, start: start, end: end) != .noError {
        return noErr
      }
      Application.engine?.lastSampleTime = sampleTime
    }


    return noErr
  }
  
  func changeInputDevice(_ device: AudioDevice) {
      Console.log("Switching Input to: \(device.name)")
      engine.stop()
      engine.setInputDevice(device)
      
      // Adjust connections
      let inputFormat = engine.inputNode.inputFormat(forBus: 0)
      engine.disconnectNodeInput(equalizers.active!.eq)
      engine.connect(engine.inputNode, to: equalizers.active!.eq, format: inputFormat)
      
      try! engine.start()
  }

  func insertPlugin(_ avUnit: AVAudioUnit) {
        Console.log("Inserting Plugin: \(avUnit.name)")
        engine.stop()
        
        engine.attach(avUnit)
        
        // Re-route: Filter -> Plugin -> Limiter
        engine.disconnectNodeOutput(filter.node)
        // engine.disconnectNodeInput(limiter.node) // Not strictly needed if overwriting connection
        
        engine.connect(filter.node, to: avUnit, format: format)
        engine.connect(avUnit, to: limiter.node, format: format)
        
        do {
            try engine.start()
        } catch {
            Console.log("Engine Start Failed: \(error)")
        }
        
        // Attempt to show UI
        avUnit.auAudioUnit.requestViewController { viewController in
            DispatchQueue.main.async {
                if let vc = viewController {
                    let win = NSWindow(contentViewController: vc)
                    win.title = avUnit.name
                    win.styleMask = [.titled, .closable, .resizable]
                    win.makeKeyAndOrderFront(nil)
                }
            }
        }
    }
    }


  deinit {
  }
}
