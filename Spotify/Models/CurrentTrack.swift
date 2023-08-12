//
//  CurrentTrack.swift
//  Spotify
//
//  Created by Carson Gross on 7/9/23.
//

import Foundation

final class CurrentTrack: NSObject, SPTAppRemoteTrack {
    var name: String
    
    var uri: String
    
    var duration: UInt
    
    var artist: SPTAppRemoteArtist
    
    var album: SPTAppRemoteAlbum
    
    var isSaved: Bool
    
    var isEpisode: Bool
    
    var isPodcast: Bool
    
    var isAdvertisement: Bool
    
    var imageIdentifier: String
    
    init(name: String, uri: String, duration: UInt, artist: SPTAppRemoteArtist, album: SPTAppRemoteAlbum, isSaved: Bool, isEpisode: Bool, isPodcast: Bool, isAdvertisement: Bool, imageIdentifier: String) {
        self.name = name
        self.uri = uri
        self.duration = duration
        self.artist = artist
        self.album = album
        self.isSaved = isSaved
        self.isEpisode = isEpisode
        self.isPodcast = isPodcast
        self.isAdvertisement = isAdvertisement
        self.imageIdentifier = imageIdentifier
    }
}
