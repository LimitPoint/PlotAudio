![PlotAudio](https://www.limit-point.com/assets/images/PlotAudio.jpg)
# PlotAudio
## Draws audio waveforms

The associated Xcode project implements a SwiftUI app for macOS and iOS that processes audio samples in a file to plot their decibel levels over time. 

Learn more about plotting audio samples from our [in-depth blog post](https://www.limit-point.com/blog/2022/plot-audio).

The subfolder *PlotAudio* contains a small set of independent files that prepare and display audio data in a specialized interactive view. The remaining files build an app around that functionality.  

A list of audio and video files for processing is included in the bundle resources subdirectories *Audio Files* and *Video Files*.

Add your own audio and video files or use the sample set provided. 

Tap on a file in the list to plot its audio.

Adjust controls for appearance and drag or tap on the audio plot to set play locations.

<img src="https://www.limit-point.com/assets/images/PlotAudio_PlotIndicator_Wavvy.jpg" height="64">

The core files that implement preparing and plotting audio data in a view: 

* DownsampleAudio : The [AVFoundation], [Accelerate] and [SwiftUI] code that processes audio samples for plotting as a [Path] with the `PlotAudio` Function.
* PlotAudioWaveformView : The [View] that draws the plot of the processed audio samples.
* PlotAudioObservable : The [ObservableObject] that handles interacting with the plot such as dragging to set play location via its `PlotAudioDelegate`, or updating when necessary.

The *PlotAudio* folder can be added to other projects to display audio plots of media [URL] or [AVAsset]. The Xcode preview of `PlotAudioWaveformView` is setup to display the audio plots of three included audio files.

[AVFoundation]: https://developer.apple.com/documentation/avfoundation
[Accelerate]: https://developer.apple.com/documentation/accelerate
[SwiftUI]: https://developer.apple.com/tutorials/swiftui
[Path]: https://developer.apple.com/documentation/swiftui/path
[View]: https://developer.apple.com/documentation/swiftui/view
[ObservableObject]: https://developer.apple.com/documentation/combine/observableobject
[AVAsset]: https://developer.apple.com/documentation/avfoundation/avasset
[URL]: https://developer.apple.com/documentation/foundation/url
