//
//  ControlView.swift
//  PlotAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/plot-audio/#ControlViewObservable
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import SwiftUI

struct commonButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(BorderlessButtonStyle())
            .font(.system(size: 32, weight: .light))
            .frame(width: 44, height: 44)
    }
}

struct PlayerControlsView: View {
    
    @ObservedObject var controlViewObservable: ControlViewObservable
    
    var body: some View {
        if let filename = controlViewObservable.fileTableObservable.currentFile?.url.lastPathComponent {
            Text(filename)
        }
        
        Text("\(controlViewObservable.plotAudioObservable.currentTimeString())")
            .monospacedDigit()
        
        HStack {
            
            if controlViewObservable.isPlaying {
                if controlViewObservable.isPaused {
                    Button(action: { controlViewObservable.resumeMedia() }, label: {
                        Label("Resume", systemImage: "play.rectangle.fill")
                    })
                    .modifier(commonButtonModifier())
                }
                else {
                    Button(action: { controlViewObservable.pauseMedia() }, label: {
                        Label("Pause", systemImage: "pause.circle.fill")
                    })
                    .modifier(commonButtonModifier())
                    .disabled(controlViewObservable.isPlaying == false)
                }
            }
            else {
                Button(action: { controlViewObservable.playSelectedMedia() }, label: {
                    Label("Play", systemImage: "play.rectangle")
                })
                .modifier(commonButtonModifier())
            }
            
            Button(action: { controlViewObservable.stopMedia() }, label: {
                Label("Stop", systemImage: "stop.circle.fill")
            })
            .modifier(commonButtonModifier())
            .disabled(controlViewObservable.isPlaying == false && controlViewObservable.isPaused == false)
        }
    }
}

struct AspectFactorView: View {
    
    @ObservedObject var controlViewObservable: ControlViewObservable
    
    @State private var editingChanged = false
    
    var body: some View {
        VStack {
            Text(String(format: "%.2f", controlViewObservable.aspectFactor))
                .foregroundColor(editingChanged ? .red : .blue)
            
            Slider(
                value: $controlViewObservable.aspectFactor,
                in: 0.5...3.0
            ) {
                Text("Aspect Factor")
            } minimumValueLabel: {
                Text("0.5")
            } maximumValueLabel: {
                Text("3")
            } onEditingChanged: { editing in
                editingChanged = editing
            }
        }
        .padding()
    }
}

struct PlotOptionsView: View {
    
    @ObservedObject var controlViewObservable: ControlViewObservable
    
    var body: some View {
        HStack {
            Toggle(isOn: $controlViewObservable.plotAudioObservable.pathGradient) {
                Text("Gradient")
            }
            .padding()
            
            Toggle(isOn: $controlViewObservable.plotAudioObservable.fillIndicator) {
                Text("Fill Indicator")
            }
            .padding()
        }
        .padding()
        
        AspectFactorView(controlViewObservable: controlViewObservable)
        
        Toggle(isOn: $controlViewObservable.plotAudioObservable.pathFrame) {
            Text("Frame")
        }
        .padding()
        
        BarsOptionsView(controlViewObservable: controlViewObservable)
    }
}

struct BarsOptionsView: View {
    
    @ObservedObject var controlViewObservable: ControlViewObservable
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text("Width")
                    Picker(selection: $controlViewObservable.plotAudioObservable.barWidth,
                           label: EmptyView(),
                           content: {
                        ForEach(kPlotAudioBarWidths, id: \.self) {
                            Text("\($0)").tag($0)
                        }
                    })
                    .pickerStyle(.automatic)
                    .frame(width: 100)
                }
                
            }
            
            VStack {
                HStack {
                    Text("Spacing")
                    Picker(selection: $controlViewObservable.plotAudioObservable.barSpacing,
                           label: EmptyView(),
                           content: {
                        ForEach(kPlotAudioBarSpacings, id: \.self) {
                            Text("\($0)").tag($0)
                        }
                    })
                    .pickerStyle(.automatic)
                    .frame(width: 100)
                }
                
            }
        }
    }
}

struct PreprocessOptionsView: View {
    
    @ObservedObject var controlViewObservable: ControlViewObservable
    
    var body: some View {
        Picker("Noise Floor", selection: $controlViewObservable.plotAudioObservable.noiseFloor) {
            Text("-90").tag(-90)
            Text("-80").tag(-80)
            Text("-70").tag(-70)
            Text("-60").tag(-60)
            Text("-50").tag(-50)
        }
        .pickerStyle(.segmented)
        .frame(width: 300)
        
        Toggle(isOn: $controlViewObservable.plotAudioObservable.pathAntialias) {
            Text("Anti-Alias")
        }
        .padding()
        
            // Changing downsampleRateSeconds will not affect the plot, only the memory required to process data
        Picker("Downsample Rate", selection: $controlViewObservable.plotAudioObservable.downsampleRateSeconds) {
            Text("1").tag(Int?.some(1))
            Text("10").tag(Int?.some(10))
            Text("60").tag(Int?.some(60))
            Text("300").tag(Int?.some(300))
            Text("Whole").tag(nil as Int?)
        }
        .pickerStyle(.segmented)
        .frame(width: 300)
        
        Text("Changing downsample rate seconds will not affect the plot, only the memory required to process data.")
            .font(.footnote).frame(width: 300)
            .padding()
    }
}

struct ControlView: View {
    
    @ObservedObject var controlViewObservable: ControlViewObservable
    
    var body: some View {
        
        VStack {
            
            PlayerControlsView(controlViewObservable: controlViewObservable)
            
            PlotOptionsView(controlViewObservable: controlViewObservable)
            
            PreprocessOptionsView(controlViewObservable: controlViewObservable)
        }
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView(controlViewObservable: ControlViewObservable(plotAudioObservable: PlotAudioObservable(), fileTableObservable: FileTableObservable()))
    }
}

