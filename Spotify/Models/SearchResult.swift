//
//  SearchResult.swift
//  Spotify
//
//  Created by Carson Gross on 7/4/23.
//

import Foundation

enum SearchResult {
    case artist(model: Artist)
    case album(model: Album)
    case track(model: AudioTrack)
    case playlist(model: Playlist)
}
