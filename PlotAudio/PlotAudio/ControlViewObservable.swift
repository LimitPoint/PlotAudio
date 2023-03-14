//
//  ControlViewObservable.swift
//  PlotAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/plot-audio/#ControlViewObservable
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation
import AVFoundation
import Combine

let kPreferredTimeScale:Int32 = 64000

class ControlViewObservable: ObservableObject, AudioPlayerDelegate, PlotAudioDelegate {
    
    @Published var mediaType:MediaType = .audio
    
    @Published var plotAudioObservable: PlotAudioObservable
    @Published var fileTableObservable: FileTableObservable
    
    var audioPlayer:AudioPlayer
    
    var videoPlayer:AVPlayer
    var videoPlayerPeriodicTimeObserver:Any?
    var videoPlayerItem:AVPlayerItem
    var videoDuration:Double = 0
    
    @Published var isPaused:Bool = false
    @Published var isPlaying:Bool = false
    
    @Published var aspectFactor:Double = 1.0
    var originalFrameSize:CGSize?
    
    var cancelBag = Set<AnyCancellable>()
    
    init(plotAudioObservable:PlotAudioObservable, fileTableObservable: FileTableObservable) {
        
        self.plotAudioObservable = plotAudioObservable
        self.fileTableObservable = fileTableObservable
        
        audioPlayer = AudioPlayer()
        
        let asset = AVAsset(url: fileTableObservable.files[0].url)
        videoDuration = asset.duration.seconds
        videoPlayer = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        videoPlayerItem = videoPlayer.currentItem! // used in seek
        
        videoPlayerPeriodicTimeObserver = self.videoPlayer.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: nil) { [weak self] cmTime in
            if let duration = self?.videoDuration {
                self?.plotAudioObservable.indicatorPercent = cmTime.seconds / duration
            }
        }
        
        audioPlayer.delegate = self
        
        self.plotAudioObservable.plotAudioDelegate = self
        
        plotAudioObservable.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send() 
        }.store(in: &cancelBag)
        
        fileTableObservable.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send() 
        }.store(in: &cancelBag)
        
        $mediaType.sink { [weak self] newMediaType in
            if newMediaType != self?.mediaType {
                DispatchQueue.main.async {
                    self?.plotAudioObservable.plotAudio()
                }
            }
            
        }.store(in: &cancelBag)
        
        $aspectFactor.sink { [weak self] newAspectFactor in
            if newAspectFactor != self?.aspectFactor {
                DispatchQueue.main.async {
                    
                    if self?.originalFrameSize == nil {
                        self?.originalFrameSize = self?.plotAudioObservable.frameSize
                    }
                    
                    if let originalFrameSize = self?.originalFrameSize, let aspectFactor = self?.aspectFactor {
                        let newHeight = originalFrameSize.height * aspectFactor
                        self?.plotAudioObservable.frameSize = CGSize(width: originalFrameSize.width, height: newHeight)
                    }
                }
            }
            
        }.store(in: &cancelBag)
    }
    
    deinit {
        print("ControlViewObservable deinit")
    }
    
    func updatePlayer(_ url:URL) {
        let asset = AVAsset(url: url)
        videoDuration = asset.duration.seconds
        self.videoPlayerItem = AVPlayerItem(asset: asset)
        self.videoPlayer.replaceCurrentItem(with: self.videoPlayerItem)
        if let periodicTimeObserver = self.videoPlayerPeriodicTimeObserver {
            self.videoPlayer.removeTimeObserver(periodicTimeObserver)
        }
        self.videoPlayerPeriodicTimeObserver = self.videoPlayer.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: nil) { [weak self] cmTime in
            if let duration = self?.videoDuration {
                if cmTime.seconds == duration {
                    self?.isPlaying = false
                    self?.isPaused = false
                    self?.plotAudioObservable.indicatorPercent = 0
                }
                else {
                    self?.plotAudioObservable.indicatorPercent = cmTime.seconds / duration
                }
                
            }
        }
    }
    
    func playSelectedMedia() {
        isPlaying = true
        isPaused = false
        if let currentFile = fileTableObservable.currentFile {
            switch mediaType {
                case .audio:
                    let _ = audioPlayer.playAudioURL(currentFile.url)
                case .video:
                    updatePlayer(currentFile.url) 
                    videoPlayer.play()
            }
        }
    }
    
        // AudioPlayerDelegate
        // set delegate in init!
    func audioPlayDone(_ player: AudioPlayer?) {
        isPlaying = false
        isPaused = false
        plotAudioObservable.indicatorPercent = 0
    }
    
        // AudioPlayerDelegate
    func audioPlayProgress(_ player: AudioPlayer?, percent: CGFloat) {
        plotAudioObservable.indicatorPercent = percent
    }
    
    func pauseMedia() {
        switch mediaType {
            case .audio:
                audioPlayer.pausePlayingAudio()
            case .video:
                videoPlayer.pause()
        }
        isPaused = true
    }
    
    func resumeMedia() {
        switch mediaType {
            case .audio:
                audioPlayer.play(percent: plotAudioObservable.indicatorPercent)
            case .video:
                videoPlayer.play()
        }
        isPaused = false
    }
    
    func stopMedia() {
        if isPaused { // prevents delay if audio player paused
            resumeMedia() 
        }
        isPlaying = false
        isPaused = false
        switch mediaType {
            case .audio:
                audioPlayer.stopPlayingAudio()
            case .video:
                videoPlayer.pause()
                videoPlayer.seek(to: CMTime.zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
    
        // PlotAudioDelegate
        // set delegate in init!
    func plotAudioDragChanged(_ value: CGFloat) {
        switch mediaType {
            case .audio:
                if isPlaying {
                    audioPlayer.stopPlayingAudio()
                }
                isPlaying = false
                isPaused = false
            case .video:
                videoPlayer.pause()
                isPlaying = false
                isPaused = false
                videoPlayer.seek(to: CMTimeMakeWithSeconds(value * videoDuration, preferredTimescale: kPreferredTimeScale), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
        
    }
    
        // PlotAudioDelegate
    func plotAudioDragEnded(_ value: CGFloat) {
        switch mediaType {
            case .audio:
                isPlaying = true
                if let currentFile = fileTableObservable.currentFile {
                    let _ = audioPlayer.playAudioURL(currentFile.url, percent: value)
                }
            case .video:
                isPlaying = true
                videoPlayer.play()
        }
        
    }
    
        // PlotAudioDelegate
    func plotAudioDidFinishPlotting() {
        self.playSelectedMedia()
    }
}

