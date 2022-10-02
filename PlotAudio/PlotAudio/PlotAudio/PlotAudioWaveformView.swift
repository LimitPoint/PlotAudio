//
//  PlotAudioWaveformView.swift
//  PlotAudio
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import AVFoundation
import SwiftUI

let gradient = LinearGradient(gradient: Gradient(colors: [.black, Color(red: 150.0/255.0, green: 226.0/255.0, blue: 248.0/255.0)]), startPoint: .topLeading, endPoint: .bottomTrailing)

let paleRed = Color(Color.RGBColorSpace.sRGB, red: 1, green: 0, blue: 0, opacity: 0.5)

struct PlotAudioWaveformView: View {
    
    @ObservedObject var plotAudioObservable: PlotAudioObservable
    
    var body: some View {
        ZStack {
                // audio plot
            if plotAudioObservable.pathGradient {
                plotAudioObservable.audioPath
                    .stroke(Color.clear, style: StrokeStyle(lineWidth: plotAudioObservable.lineWidth(), lineCap: .round, lineJoin: .round))
                    .overlay(
                        gradient.mask(
                            plotAudioObservable.audioPath
                                .stroke(Color.red, style: StrokeStyle(lineWidth: plotAudioObservable.lineWidth(), lineCap: .round, lineJoin: .round))
                        )
                    )
                    //.clipShape(Rectangle()) // clips to the view - first bar clipped
            }
            else {
                plotAudioObservable.audioPath
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: plotAudioObservable.lineWidth(), lineCap: .round, lineJoin: .round))
            }
            
                // indicator (filled or stroked)
            if plotAudioObservable.indicatorPercent > 0 {
                if plotAudioObservable.fillIndicator {
                    Path { path in 
                        path.addRect(CGRect(x: 0, y: 0, width: plotAudioObservable.indicatorPercent * plotAudioObservable.frameSize.width, height: plotAudioObservable.frameSize.height).insetBy(dx: 0, dy: -plotAudioObservable.lineWidth()/2))
                    }
                    .fill(paleRed)
                }
                else {
                    Path { path in 
                        path.move(to: CGPoint(x: plotAudioObservable.indicatorPercent * plotAudioObservable.frameSize.width, y:  -plotAudioObservable.lineWidth()/2))
                        path.addLine(to: CGPoint(x: plotAudioObservable.indicatorPercent * plotAudioObservable.frameSize.width, y: plotAudioObservable.frameSize.height + plotAudioObservable.lineWidth()/2))
                    }
                    .stroke(Color.red, lineWidth: 2)
                }
            }
            
                // selection range
            if plotAudioObservable.selectionRange.upperBound > plotAudioObservable.selectionRange.lowerBound {
                Path { path in 
                    path.addRect(CGRect(x: plotAudioObservable.selectionRange.lowerBound * plotAudioObservable.frameSize.width, y: 0, width: (plotAudioObservable.selectionRange.upperBound - plotAudioObservable.selectionRange.lowerBound) * plotAudioObservable.frameSize.width, height: plotAudioObservable.frameSize.height).insetBy(dx: 0, dy: -plotAudioObservable.lineWidth()/2))
                }
                .stroke(.yellow, lineWidth: 1)
            }
            
                // optional frame
            if plotAudioObservable.pathFrame {
                Path { path in
                    path.addRect(CGRect(origin: CGPoint(x: 0, y: 0), size: plotAudioObservable.frameSize).insetBy(dx: 0, dy: -plotAudioObservable.lineWidth()/2))
                }
                .stroke(Color(red: 0.0, green: 0, blue: 0.0, opacity: 1), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: plotAudioObservable.frameSize.width, height: plotAudioObservable.frameSize.height, alignment: Alignment.center)
        .background(Color(red: 1, green: 1, blue: 1, opacity: 0.1))
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged({ value in
                let percent =  min(max(0, value.location.x / plotAudioObservable.frameSize.width), 1)
                plotAudioObservable.indicatorPercent = percent
                plotAudioObservable.handleDragChanged(value:percent)
            })
                .onEnded({ value in
                    let percent = min(max(0, value.location.x / plotAudioObservable.frameSize.width), 1)
                    plotAudioObservable.indicatorPercent = percent
                    plotAudioObservable.handleDragEnded(value: percent)
                })
        )
        .overlay(
            Group {
                if plotAudioObservable.isPlotting {
                    ProgressView("")
                }
            }
        )
    }
}

let kClockURL = Bundle.main.url(forResource: "PlotAudio_ClockSample", withExtension: "m4a")!
let kPianoURL = Bundle.main.url(forResource: "PlotAudio_PianoSample", withExtension: "m4a")!
let kTubaURL = Bundle.main.url(forResource: "PlotAudio_TubaSample", withExtension: "m4a")!

struct PlotAudioWaveformView_Previews: PreviewProvider {
    static var previews: some View {
        
        VStack {
            PlotAudioWaveformView(plotAudioObservable: PlotAudioObservable(url: kClockURL, pathGradient: true, pathFrame: true, barWidth: 3, barSpacing: 2))
            
            PlotAudioWaveformView(plotAudioObservable: PlotAudioObservable(url: kTubaURL, pathGradient: true, barWidth: 3, barSpacing: 2, frameSize: CGSize(width: 300, height: 200)))
            
            PlotAudioWaveformView(plotAudioObservable: PlotAudioObservable(asset: AVAsset(url: kPianoURL)))
        }
        
    }
}

