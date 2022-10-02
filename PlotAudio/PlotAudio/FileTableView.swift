//
//  FileTableView.swift
//  PlotAudio
//
//  Created by Joseph Pagliaro on 10/1/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation
import SwiftUI

struct FileTableViewRowView: View {
    
    var file:File
    
    var body: some View {
        HStack {
            Text("\(file.url.lastPathComponent) [\(file.duration)]")
        }
    }
}

struct FileTableView: View {
    
    @ObservedObject var fileTableObservable: FileTableObservable
    
    func title() -> String {
        return ("\(fileTableObservable.mediaType.rawValue.capitalized) Files")
    }
    
    var body: some View {
        
        if fileTableObservable.files.count == 0 {
            Text("No Media Files")
                .padding()
        }
        else {
#if os(macOS)
            VStack {
                Text(title())
                    .font(.title)
                List(fileTableObservable.files, selection: $fileTableObservable.selectedFileID) {
                    FileTableViewRowView(file: $0)
                } 
            }
#else
            NavigationView {
                List(fileTableObservable.files, selection: $fileTableObservable.selectedFileID) {
                    FileTableViewRowView(file: $0)
                }
                .navigationTitle(title())
                .environment(\.editMode, .constant(.active))  
                
            }
            .navigationViewStyle(StackNavigationViewStyle())
#endif
        }
        
    }
}

struct FileTableView_Previews: PreviewProvider {
    static var previews: some View {
        FileTableView(fileTableObservable: FileTableObservable())
    }
}

