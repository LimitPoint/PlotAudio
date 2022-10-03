//
//  PlotAudioAppView.swift
//  PlotAudio
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import SwiftUI
import AVFoundation
import AVKit

struct PlotAudioAppView: View {
    
    @ObservedObject var plotAudioObservable: PlotAudioObservable
    @ObservedObject var fileTableObservable:FileTableObservable
    @ObservedObject var controlViewObservable: ControlViewObservable
        
    var body: some View {
        ScrollView {
            VStack {
                Picker("Media Type", selection: $fileTableObservable.mediaType) {
                    ForEach(MediaType.allCases) { type in
                        Text(type.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                FileTableView(fileTableObservable: fileTableObservable)
                    .onChange(of: fileTableObservable.selectedFileID) { newSelectedFileID in
                        if newSelectedFileID != nil, let index = fileTableObservable.files.firstIndex(where: {$0.id == newSelectedFileID}) {
                            let fileURL = fileTableObservable.files[index].url
                            plotAudioObservable.asset = AVAsset(url: fileURL)
                        }
                    }
                    .frame(minHeight: 300)
                
                if fileTableObservable.mediaType == .video {
                    VideoPlayer(player: controlViewObservable.videoPlayer)
                        .frame(minHeight: 300)
                }
                
                PlotAudioWaveformView(plotAudioObservable: plotAudioObservable)
                
                ControlView(controlViewObservable: controlViewObservable)
            }
            .onChange(of: fileTableObservable.mediaType) { newMediaType in
                controlViewObservable.stopMedia()
                controlViewObservable.mediaType = newMediaType
                fileTableObservable.selectIndex(3)
            }
            .onAppear {
                fileTableObservable.selectIndex(3)
            }
        }
        
    }
}

struct PlotAudioAppView_Previews: PreviewProvider {
    static var previews: some View {
        PlotAudioAppView(plotAudioObservable: PlotAudioObservable(), fileTableObservable: FileTableObservable(), controlViewObservable: ControlViewObservable(plotAudioObservable: PlotAudioObservable(), fileTableObservable: FileTableObservable()))
    }
}
