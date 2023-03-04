//
//  PlotAudioApp.swift
//  PlotAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/plot-audio/#PlotAudioApp
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import SwiftUI
import Accelerate

func DecibelExample() {
    var bufferSamplesD:[Double] = [1.0, 3.0, 5.0]
    
    vDSP.convert(amplitude: bufferSamplesD, toDecibels: &bufferSamplesD, zeroReference: 5.0)
    
    print("vDSP.convert = \(bufferSamplesD)") 
        // = [-13.979400086720375, -4.436974992327126, 0.0]
    
        // compare
    print("20 * log10 = \([20 * log10(1.0/5.0), 20 * log10(3.0/5.0), 20 * log10(5.0/5.0)])") 
        // = [-13.979400086720375, -4.436974992327128, 0.0]
    
    print(Int16.max)
        // 32767
    
    print(20 * log10(1.0/Double(Int16.max)))
        // -90.30873362283398
}

func downsample(audioSamples:[Int16], decimationFactor:Int) -> [Double]? {
    
    guard decimationFactor <= audioSamples.count else {
        print("downsample, error : decimationFactor \(decimationFactor) > audioSamples.count \(audioSamples.count)")
        return nil
    }
    
    print("downsample, array: \(audioSamples)")
    print("decimationFactor \(decimationFactor)")
    
    var audioSamplesD = [Double](repeating: 0, count: audioSamples.count)
    
    vDSP.convertElements(of: audioSamples, to: &audioSamplesD)
    
    let filter = [Double](repeating: 1.0 / Double(decimationFactor), count:decimationFactor)
    
    let downsamplesLength = audioSamplesD.count / decimationFactor
    var downsamples = [Double](repeating: 0.0, count:downsamplesLength)
    
    vDSP_desampD(audioSamplesD, vDSP_Stride(decimationFactor), filter, &downsamples, vDSP_Length(downsamplesLength), vDSP_Length(decimationFactor))
    
    print("downsample, result: \(downsamples)")
    
    return downsamples
}

func DecimationExample(audioSamples:[Int16], desiredSize:Int) {
    
    guard desiredSize <= audioSamples.count else {
        print("Can't decimate : desiredSize \(desiredSize) > audioSamples.count \(audioSamples.count)")
        return 
    }
    
    let decimationFactor = audioSamples.count / desiredSize
    
    print("audioSamples \(audioSamples)")
    print("audioSamples.count = \(audioSamples.count)")
    print("desiredSize = \(desiredSize)")
    print("decimationFactor = \(decimationFactor)")
    
    print("\nWHOLE:\n")
    
    var downsamples_whole:[Double] = [] 
    
        // downsample whole at once
    if let downsamples = downsample(audioSamples: audioSamples, decimationFactor: decimationFactor) {
        downsamples_whole.append(contentsOf: downsamples)
    }
    
    print("\nPROGRESSIVE:\n")
    
        // downsample in blocks of size greater than a threshold
    var downsamples_blocks:[Double] = [] 
    
    var block:[Int16] = []
    let blockSizeThreshold = 3
    var blockCount:Int = 0
    
        // read a sample at a time into a block
    for sample in audioSamples {
        
        block.append(sample)
        
            // process clock when threshold exceeded
        if block.count > blockSizeThreshold {
            
            blockCount += 1
            print("block \(blockCount) = \(block)")
            
                // downsample block
            if let blockDownsampled = downsample(audioSamples: block, decimationFactor: decimationFactor) {
                downsamples_blocks.append(contentsOf: blockDownsampled)
            }
            
                // calculate number of leftover samples not processed in decimation
            let remainder = block.count.quotientAndRemainder(dividingBy: decimationFactor).remainder
            
                // save leftover
            var end:[Int16] = []
            if block.count-1 >= block.count-remainder { 
                end = Array(block[block.count-remainder...block.count-1])
                
            }
            
            print("end = \(end)\n")
            
            block.removeAll()
                // restore leftover
            block.append(contentsOf: end)
        }
    }
    
        // process anything left
    if block.count > 0 {
        print("block (final) = \(block)")
        if let blockDownsampled = downsample(audioSamples: block, decimationFactor: decimationFactor) {
            downsamples_blocks.append(contentsOf: blockDownsampled)
            print("final block downsamples = \(blockDownsampled)\n")
        }
    }
    
    print("downsamples:\(downsamples_whole) (whole)")
    print("downsamples:\(downsamples_blocks) (blocks)")
}

@main
struct PlotAudioApp: App {
    
    init() {
            // blog examples
        DecimationExample(audioSamples:[3,2,1,2,2,1,7], desiredSize:2)
        DecibelExample() 
    }
    
    var body: some Scene {
        WindowGroup {
            PlotAudioAppView(controlViewObservable: ControlViewObservable(plotAudioObservable: PlotAudioObservable(), fileTableObservable: FileTableObservable()))
        }
        
    }
}

