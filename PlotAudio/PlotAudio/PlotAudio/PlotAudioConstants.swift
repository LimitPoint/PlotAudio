//
//  PlotAudioConstants.swift
//  PlotAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/plot-audio/
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation
import SwiftUI

func ScreenSize() -> CGSize {
    var width:CGFloat = 0
    var height:CGFloat = 0
    
#if os(macOS)
    if let screen = NSScreen.main {
        let rect = screen.frame
        height = rect.size.height * 0.9
        width = rect.size.width * 0.5
    }
#elseif os(iOS)
    width = UIScreen.main.bounds.width
    height = UIScreen.main.bounds.height
#endif
    return CGSize(width: width, height: height)
}

let kPlotAudioHeight = 35.0
let kPlotAudioPathGradient = false
let kPlotAudioPathFrame = false
let kPlotAudioBarWidth = 1
let kPlotAudioBarSpacing = 0

let kPlotAudioPathAntialias = true

let kPlotAudioBarWidths:[Int] = [1,2,3,4,5,6,7,8,9,10]
let kPlotAudioBarSpacings:[Int] = [0,1,2,3,4,5,6,7,8,9]

func DefaultPlotAudioFrameSize() -> CGSize {
    return  CGSize(width: ScreenSize().width - CGFloat(kPlotAudioBarWidths.last!/2), height: kPlotAudioHeight)
}

