//
//  PlotAudioAppView.swift
//  PlotAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/plot-audio/#PlotAudioAppView
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import SwiftUI
import AVFoundation
import AVKit

struct PlotAudioAppView: View {
    
    @StateObject var controlViewObservable: ControlViewObservable
        
    var body: some View {
        ScrollView {
            VStack {
                Picker("Media Type", selection: $controlViewObservable.fileTableObservable.mediaType) {
                    ForEach(MediaType.allCases) { type in
                        Text(type.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                FileTableView(fileTableObservable: controlViewObservable.fileTableObservable)
                    .onChange(of: controlViewObservable.fileTableObservable.selectedFileID) { newSelectedFileID in
                        if newSelectedFileID != nil, let index = controlViewObservable.fileTableObservable.files.firstIndex(where: {$0.id == newSelectedFileID}) {
                            let fileURL = controlViewObservable.fileTableObservable.files[index].url
                            controlViewObservable.plotAudioObservable.asset = AVAsset(url: fileURL)
                        }
                    }
                    .frame(minHeight: 300)
                
                if controlViewObservable.fileTableObservable.mediaType == .video {
                    VideoPlayer(player: controlViewObservable.videoPlayer)
                        .frame(minHeight: 300)
                }
                
                PlotAudioWaveformView(plotAudioObservable: controlViewObservable.plotAudioObservable)
                
                ControlView(controlViewObservable: controlViewObservable)
            }
            .onChange(of: controlViewObservable.fileTableObservable.mediaType) { newMediaType in
                controlViewObservable.stopMedia()
                controlViewObservable.mediaType = newMediaType
                controlViewObservable.fileTableObservable.selectIndex(3)
            }
            .onAppear {
                controlViewObservable.plotAudioObservable.pathGradient = true
                controlViewObservable.plotAudioObservable.barWidth = 3
                controlViewObservable.plotAudioObservable.barSpacing = 2
                
                controlViewObservable.fileTableObservable.selectIndex(3)
            }
        }
        
    }
}

struct PlotAudioAppView_Previews: PreviewProvider {
    static var previews: some View {
        PlotAudioAppView(controlViewObservable: ControlViewObservable(plotAudioObservable: PlotAudioObservable(), fileTableObservable: FileTableObservable()))
    }
}
