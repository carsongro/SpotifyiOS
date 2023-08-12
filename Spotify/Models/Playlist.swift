//
//  Playlist.swift
//  Spotify
//
//  Created by Carson Gross on 6/25/23.
//

import Foundation

struct Playlist: Codable {
    let description: String?
    let external_urls: [String: String]?
    let id: String
    let images: [APIImage]
    let name: String
    let owner: User
    let tracks: PlaylistTracks
    var next: String?
}

struct PlaylistTracks: Codable {
    let total: Int
}

struct User: Codable {
    let display_name: String
    let external_urls: [String: String]
    let id: String
}
