//
//  FeaturedPlaylistsResponse.swift
//  Spotify
//
//  Created by Carson Gross on 6/30/23.
//

import Foundation

struct FeaturedPlaylistsResponse: Codable {
    let playlists: PlaylistResponse
}

struct CategoryPlaylistsResponse: Codable {
    let playlists: PlaylistResponse
}

struct PlaylistResponse: Codable {
    let items: [Playlist?]
}
