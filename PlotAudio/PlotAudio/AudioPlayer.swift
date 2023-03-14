//
//  AudioPlayer.swift
//  PlotAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/plot-audio/#AudioPlayer
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import AVFoundation

protocol AudioPlayerDelegate: AnyObject { // AnyObject - required for AudioPlayer's weak reference for delegate (only reference types can have weak reference to prevent retain cycle)
    func audioPlayProgress(_ player:AudioPlayer?, percent: CGFloat)
    func audioPlayDone(_ player:AudioPlayer?, percent: CGFloat)
}

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    var audioPlayer: AVAudioPlayer?
    var timer:Timer?
    
    weak var delegate: AudioPlayerDelegate?
    
    deinit {
        stopTimer()
    }
    
    func isPlaying() -> Bool {
        
        guard let player = self.audioPlayer else {
            return false
        }
        
        return player.isPlaying
    }
    
    func stopPlayingAudio() {
        if let audioPlayer = audioPlayer,  audioPlayer.isPlaying {
            audioPlayer.stop() // this won't invoke 'audioPlayerDidFinishPlaying'
            stopTimer()
            delegate?.audioPlayDone(self, percent: audioPlayer.currentTime / audioPlayer.duration)
        }
    }
    
    func pausePlayingAudio() {
        if let audioPlayer = audioPlayer,  audioPlayer.isPlaying {
            stopTimer()
            audioPlayer.pause()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func startTimer() {
        let schedule = {
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
                
                if let player = self?.audioPlayer {
                    let percent = player.currentTime / player.duration
                    
                    self?.delegate?.audioPlayProgress(self, percent: CGFloat(percent))
                }
                
            }
        }
        
        if Thread.isMainThread {
            schedule()
        }
        else {
            DispatchQueue.main.sync {
                schedule()
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopTimer()
        delegate?.audioPlayDone(self, percent: 0)
    }
    
    func play(percent:Double) {
        
        guard let player = audioPlayer else { return }
        
        stopTimer()
        
        let delay:TimeInterval = 0.01
        let now = player.deviceCurrentTime
        let timeToPlay = now + delay
        
        player.currentTime = percent * player.duration
        
        startTimer()
        
        player.play(atTime: timeToPlay)
    }
    
    func playAudioURL(_ url:URL, percent:Double = 0) -> Bool {
        
        if FileManager.default.fileExists(atPath: url.path) == false {
            Swift.print("There is no audio file to play.")
            return false
        }
        
        do {
            stopTimer()
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            guard let player = audioPlayer else { return false }
            
            player.delegate = self
            player.prepareToPlay()
            
            play(percent: percent)
        }
        catch let error {
            print(error.localizedDescription)
            return false
        }
        
        return true
    }
}
