//
//  CurrentAlbum.swift
//  Spotify
//
//  Created by Carson Gross on 7/9/23.
//

import Foundation

final class CurrentAlbum: NSObject, SPTAppRemoteAlbum {
    var name: String
    
    var uri: String
    
    init(name: String, uri: String) {
        self.name = name
        self.uri = uri
    }
}
