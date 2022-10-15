//
//  FileTableObservable.swift
//  PlotAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/plot-audio/#FileTableObservable
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation
import Combine

enum MediaType: String, CaseIterable, Identifiable {
    case audio, video
    var id: Self { self }
}

let kAudioFilesSubdirectory = "Audio Files"
let kVideoFilesSubdirectory = "Video Files"

let kAudioExtensions: [String] = ["aac", "m4a", "aiff", "aif", "wav", "mp3", "caf", "m4r", "flac", "mp4"]
let kVideoExtensions: [String] = ["mov"]

class FileTableObservable: ObservableObject {
    
    @Published var mediaType:MediaType = .audio
    
    @Published var files:[File] = []
    @Published var selectedFileID:UUID?
    @Published var currentFile:File?
    
    var cancelBag = Set<AnyCancellable>()
    
    func selectIndex(_ index:Int) {
        currentFile = files[index]
        selectedFileID = files[index].id
    }
    
    func loadFiles(extensions:[String] = kAudioExtensions, subdirectory:String = kAudioFilesSubdirectory) {
        files = []
        for ext in extensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: subdirectory) {
                for url in urls {
                    files.append(File(url: url))
                }
            }
        }
        files.sort(by: { $0.url.lastPathComponent > $1.url.lastPathComponent })
    }
    
    func loadFiles(mediaType:MediaType) {
        switch mediaType {
            case .audio:
                loadFiles(extensions:kAudioExtensions, subdirectory:kAudioFilesSubdirectory)
            case .video:
                loadFiles(extensions:kVideoExtensions, subdirectory:kVideoFilesSubdirectory)
        }
    }
    
    init() {
        loadFiles(mediaType: .audio)
        
        $selectedFileID.sink { [weak self] newSelectedFileID in
            if newSelectedFileID != self?.selectedFileID, let index = self?.files.firstIndex(where: {$0.id == newSelectedFileID}) {
                self?.currentFile = self?.files[index]
            }
            
        }.store(in: &cancelBag)
        
        $mediaType.sink { [weak self] newMediaType in
            if newMediaType != self?.mediaType {
                self?.loadFiles(mediaType: newMediaType)
            }
            
        }.store(in: &cancelBag)
    }
}

