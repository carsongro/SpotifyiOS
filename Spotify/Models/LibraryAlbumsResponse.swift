//
//  LibraryAlbumsResponse.swift
//  Spotify
//
//  Created by Carson Gross on 7/8/23.
//

import Foundation

struct LibraryAlbumsResponse: Codable {
    let items: [SavedAlbum]
}

struct SavedAlbum: Codable {
    let album: Album
    let added_at: String
}
