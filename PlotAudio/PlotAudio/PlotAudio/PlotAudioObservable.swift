//
//  PlotAudioObservable.swift
//  PlotAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/plot-audio/#PlotAudioObservable
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

protocol PlotAudioDelegate : AnyObject  {
    func plotAudioDragChanged(_ value: CGFloat)
    func plotAudioDragEnded(_ value: CGFloat)
    func plotAudioDidFinishPlotting()
}

class PlotAudioObservable: ObservableObject  {
    
    weak var plotAudioDelegate:PlotAudioDelegate?
    
    @Published var asset:AVAsset?
    
    @Published var audioSamples:[Double]?
    @Published var noiseFloor:Int = -70
    @Published var downsampleRateSeconds:Int? = 10
    @Published var frameSize:CGSize
    @Published var indicatorPercent:Double = 0
    @Published var fillIndicator:Bool = true
    @Published var selectionRange:ClosedRange<Double> = 0.0...0.0
    @Published var audioPath = Path()
    
    var audioDuration:Double = 0
    
    @Published var isPlotting:Bool = false
    
    @Published var pathGradient:Bool
    @Published var pathFrame:Bool
    @Published var barWidth:Int
    @Published var barSpacing:Int
    
    @Published var pathAntialias:Bool
    
    var cancelBag = Set<AnyCancellable>()
    
    func currentTimeString() -> String {
        return AVAsset.secondsToString(secondsIn: indicatorPercent * audioDuration)
    }
    
    func downsampleAudioToPlot(asset:AVAsset, downsampleRateSeconds:Int?) {
        
        isPlotting = true
        
        audioDuration = asset.duration.seconds
        
        DownsampleAudio(noiseFloor: Double(self.noiseFloor), antialias: pathAntialias).run(asset: asset, downsampleCount: self.downsampleCount(), downsampleRateSeconds: downsampleRateSeconds) { audioSamples in
            DispatchQueue.main.async { [weak self] in
                self?.audioSamples = audioSamples
                self?.isPlotting = false
                
                self?.plotAudioDelegate?.plotAudioDidFinishPlotting()
            }
        }
    }
    
    func updatePaths() {
        if let audioSamples = self.audioSamples {
            if let audioPath = PlotAudio(audioSamples: audioSamples, frameSize: frameSize, noiseFloor: Double(self.noiseFloor)) {
                self.audioPath = audioPath
            }
        }
    }
    
    func plotAudio() {
        if let asset = asset {
            downsampleAudioToPlot(asset: asset, downsampleRateSeconds: self.downsampleRateSeconds)
        }
        
    }
    
    func lineWidth() -> Double {
        return Double(barWidth)
    }
    
    func downsampleCount() -> Int {
        return Int(self.frameSize.width / Double((self.barSpacing + self.barWidth)))
    }
    
    func handleDragChanged(value:CGFloat) {
        plotAudioDelegate?.plotAudioDragChanged(value)
    }
    
    func handleDragEnded(value:CGFloat) {
        plotAudioDelegate?.plotAudioDragEnded(value)
    }
    
    convenience init(url:URL, pathGradient:Bool = kPlotAudioPathGradient, pathFrame:Bool = kPlotAudioPathFrame, barWidth:Int = kPlotAudioBarWidth, barSpacing:Int = kPlotAudioBarSpacing, frameSize:CGSize = DefaultPlotAudioFrameSize(), pathAntialias:Bool = kPlotAudioPathAntialias) {
        
        self.init(asset: AVAsset(url: url), pathGradient:pathGradient, pathFrame:pathFrame, barWidth:barWidth, barSpacing:barSpacing, frameSize:frameSize, pathAntialias: pathAntialias)
    }
    
    init(asset:AVAsset? = nil, pathGradient:Bool = kPlotAudioPathGradient, pathFrame:Bool = kPlotAudioPathFrame, barWidth:Int = kPlotAudioBarWidth, barSpacing:Int = kPlotAudioBarSpacing, frameSize:CGSize = DefaultPlotAudioFrameSize(), pathAntialias:Bool = kPlotAudioPathAntialias) {
        
        if let asset = asset {
            self.asset = asset
        }
        
        self.frameSize = frameSize
        self.pathGradient = pathGradient
        self.pathFrame = pathFrame
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        
        self.pathAntialias = pathAntialias
        
        $audioSamples.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updatePaths()
            }
        }
        .store(in: &cancelBag)
        
        $noiseFloor.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.plotAudio()
            }
        }
        .store(in: &cancelBag)
        
        $barWidth.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.plotAudio()
            }
        }
        .store(in: &cancelBag)
        
        $barSpacing.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.plotAudio()
            }
        }
        .store(in: &cancelBag)
        
        $downsampleRateSeconds.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.plotAudio()
            }
        }
        .store(in: &cancelBag)
        
        $frameSize.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updatePaths()
            }
        }
        .store(in: &cancelBag)
        
        $asset.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.plotAudio()
            }
            
        }.store(in: &cancelBag)
        
        $pathAntialias.sink { [weak self] newPathAntialias in
            if self?.pathAntialias != newPathAntialias {
                DispatchQueue.main.async {
                    self?.plotAudio()
                }
            }
        }.store(in: &cancelBag)
        
    }
    
    deinit {
        print("PlotAudioObservable deinited")
    }
}

