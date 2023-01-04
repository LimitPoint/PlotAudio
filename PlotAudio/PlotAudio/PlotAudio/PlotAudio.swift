//
//  PlotAudio.swift
//  PlotAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/plot-audio/#DownsampleAudio
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import AVFoundation
import Accelerate
import SwiftUI

let kPAAudioReaderSettings = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM) as AnyObject,
    AVLinearPCMBitDepthKey: 16 as AnyObject,
    AVLinearPCMIsBigEndianKey: false as AnyObject,
    AVLinearPCMIsFloatKey: false as AnyObject,
    AVNumberOfChannelsKey: 1 as AnyObject, 
    AVLinearPCMIsNonInterleaved: false as AnyObject]

let downsampleAudioQueue: DispatchQueue = DispatchQueue(label: "com.limit-point.downsampleAudioQueue", autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem)

class DownsampleAudio {
    
    let running = DispatchSemaphore(value: 0)
    var noiseFloor:Double
    var antialias:Bool
    
    init(noiseFloor:Double, antialias:Bool) {
        self.noiseFloor = noiseFloor
        self.antialias = antialias
    }
    
    deinit {
        print("DownsampleAudio deinit")
    }
    
    func audioReader(asset:AVAsset, outputSettings: [String : Any]?) -> (audioTrack:AVAssetTrack?, audioReader:AVAssetReader?, audioReaderOutput:AVAssetReaderTrackOutput?) {
        
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            if let audioReader = try? AVAssetReader(asset: asset)  {
                let audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
                return (audioTrack, audioReader, audioReaderOutput)
            }
        }
        
        return (nil, nil, nil)
    }
    
    func extractSamples(_ sampleBuffer:CMSampleBuffer) -> [Int16]? {
        
        if let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
            
            let sizeofInt16 = MemoryLayout<Int16>.size
            
            let bufferLength = CMBlockBufferGetDataLength(dataBuffer)
            
            var data = [Int16](repeating: 0, count: bufferLength / sizeofInt16)
            
            CMBlockBufferCopyDataBytes(dataBuffer, atOffset: 0, dataLength: bufferLength, destination: &data)
            
            return data
        }
        
        return nil
    }
    
    func downsample(_ audioSamples:[Int16], decimationFactor:Int) -> [Double]? {
        
        guard decimationFactor <= audioSamples.count else {
            return nil
        }
        
            // convert to decibels
        var audioSamplesD = [Double](repeating: 0, count: audioSamples.count)
        
        vDSP.convertElements(of: audioSamples, to: &audioSamplesD)
        
        vDSP.absolute(audioSamplesD, result: &audioSamplesD)
        
        vDSP.convert(amplitude: audioSamplesD, toDecibels: &audioSamplesD, zeroReference: Double(Int16.max))
        
        audioSamplesD = vDSP.clip(audioSamplesD, to: noiseFloor...0)
        
            // downsample
        var filter = [Double](repeating: 1.0 / Double(decimationFactor), count:decimationFactor)
        
        if antialias == false {
            filter = [1.0]
        }
        
        let downsamplesLength = Int(audioSamplesD.count / decimationFactor)
        var downsamples = [Double](repeating: 0.0, count:downsamplesLength)
        
        vDSP_desampD(audioSamplesD, vDSP_Stride(decimationFactor), filter, &downsamples, vDSP_Length(downsamplesLength), vDSP_Length(filter.count))
        
        return downsamples
    }
    
    func readAndDownsampleAudioSamples(asset:AVAsset, downsampleCount:Int, completion: @escaping ([Double]?) -> ()) {
        
        let (_, reader, readerOutput) = self.audioReader(asset:asset, outputSettings: kPAAudioReaderSettings)
        
        guard let audioReader = reader,
              let audioReaderOutput = readerOutput
        else {
            return completion(nil)
        }
        
        if audioReader.canAdd(audioReaderOutput) {
            audioReader.add(audioReaderOutput)
        }
        else {
            return completion(nil)
        }
        
        var audioSamples:[Int16] = [] 
        
        if audioReader.startReading() {
            
            while audioReader.status == .reading {
                
                autoreleasepool { [weak self] in
                    
                    if let sampleBuffer = audioReaderOutput.copyNextSampleBuffer(), let bufferSamples = self?.extractSamples(sampleBuffer) {
                        audioSamples.append(contentsOf: bufferSamples)
                    }
                    else {
                        audioReader.cancelReading()
                    }
                }
            }
        }
        
        let totalSampleCount = asset.audioBufferAndSampleCounts(kPAAudioReaderSettings).sampleCount
        let decimationFactor = totalSampleCount / downsampleCount
        
        guard let downsamples = downsample(audioSamples, decimationFactor: decimationFactor) else {
            completion(nil)
            return 
        }
        
        completion(downsamples)
    }
    
    func readAndDownsampleAudioSamples(asset:AVAsset, downsampleCount:Int, downsampleRateSeconds:Int, completion: @escaping ([Double]?) -> ()) {
        
        let (_, reader, readerOutput) = self.audioReader(asset:asset, outputSettings: kPAAudioReaderSettings)
        
        guard let audioReader = reader,
              let audioReaderOutput = readerOutput
        else {
            return completion(nil)
        }
        
        if audioReader.canAdd(audioReaderOutput) {
            audioReader.add(audioReaderOutput)
        }
        else {
            return completion(nil)
        }
        
        guard let sampleBuffer = asset.audioSampleBuffer(outputSettings:kPAAudioReaderSettings),
              let sampleBufferSourceFormat = CMSampleBufferGetFormatDescription(sampleBuffer),
              let audioStreamBasicDescription = sampleBufferSourceFormat.audioStreamBasicDescription else {
            return completion(nil)
        }
        
        let totalSampleCount = asset.audioBufferAndSampleCounts(kPAAudioReaderSettings).sampleCount
        let audioSampleRate = audioStreamBasicDescription.mSampleRate
        
        guard downsampleCount <= totalSampleCount else {
            return completion(nil)
        }
        
        let decimationFactor = totalSampleCount / downsampleCount
        
        var downsamples:[Double] = [] 
        
        var audioSamples:[Int16] = []
        let audioSampleSizeThreshold = Int(audioSampleRate) * downsampleRateSeconds
        
        if audioReader.startReading() {
            
            while audioReader.status == .reading {
                
                autoreleasepool { [weak self] in
                    
                    if let sampleBuffer = audioReaderOutput.copyNextSampleBuffer(), let bufferSamples = self?.extractSamples(sampleBuffer) {
                        
                        audioSamples.append(contentsOf: bufferSamples)
                        
                        if audioSamples.count > audioSampleSizeThreshold {
                            
                            if let audioSamplesDownsamples = downsample(audioSamples, decimationFactor: decimationFactor)  {
                                downsamples.append(contentsOf: audioSamplesDownsamples)
                            }
                            
                                // calculate number of leftover samples not processed in decimation
                            let remainder = audioSamples.count.quotientAndRemainder(dividingBy: decimationFactor).remainder
                            
                                // save leftover
                            var end:[Int16] = []
                            if audioSamples.count-1 >= audioSamples.count-remainder { 
                                end = Array(audioSamples[audioSamples.count-remainder...audioSamples.count-1])
                            }
                            audioSamples.removeAll()
                                // restore leftover
                            audioSamples.append(contentsOf: end)
                        }
                    }
                    else {
                        audioReader.cancelReading()
                    }
                }
            }
            
            if audioSamples.count > 0 {
                if let audioSamplesDownsamples = downsample(audioSamples, decimationFactor: decimationFactor)  {
                    downsamples.append(contentsOf: audioSamplesDownsamples)
                }
            }
        }
        
        completion(downsamples)
    }
    
    func run(asset:AVAsset, downsampleCount:Int, downsampleRateSeconds:Int?, completion: @escaping ([Double]?) -> ()) {
        downsampleAudioQueue.async { [weak self] in
            
            guard let self = self else {
                return
            }
            
            if let downsampleRateSeconds = downsampleRateSeconds {
                self.readAndDownsampleAudioSamples(asset: asset, downsampleCount: downsampleCount, downsampleRateSeconds: downsampleRateSeconds) { audioSamples in
                    print("audio downsampled progressively")
                    self.running.signal()
                    completion(audioSamples)
                }
            }
            else {
                self.readAndDownsampleAudioSamples(asset: asset, downsampleCount: downsampleCount) { audioSamples in
                    print("audio downsampled")
                    self.running.signal()
                    completion(audioSamples)
                }
            }
            
            self.running.wait()
        }
    }
}

func PlotAudio(audioSamples:[Double], frameSize:CGSize, noiseFloor:Double) -> Path? {
    
    let sampleCount = audioSamples.count
    
    guard sampleCount > 0 else {
        return nil
    }
    
    let audioSamplesMaximum = vDSP.maximum(audioSamples)
    let midPoint = frameSize.height / 2
    let deltaT = frameSize.width / Double(sampleCount)
    
    let audioPath = Path { path in
        
        for i in 0...sampleCount-1 {
            
            var scaledSample = midPoint
            
            if audioSamplesMaximum != noiseFloor {
                scaledSample *= (audioSamples[i] - noiseFloor) / (audioSamplesMaximum - noiseFloor)
            }
            
            path.move(to: CGPoint(x: deltaT * Double(i), y: midPoint - scaledSample))
            path.addLine(to: CGPoint(x: deltaT * Double(i), y: midPoint + scaledSample))
            
        }
    }
    
    return audioPath
}

