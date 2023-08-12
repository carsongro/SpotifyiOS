//
//  PlaylistDetailsResponse.swift
//  Spotify
//
//  Created by Carson Gross on 7/2/23.
//

import Foundation

struct PlaylistDetailsResponse: Codable {
    let description: String
    let external_urls: [String: String]
    let id: String
    let images: [APIImage]
    let name: String
    let tracks: PlaylistTracksResponse
}

struct PlaylistTracksResponse: Codable {
    let items: [PlaylistItem]
    let limit: Int
    let next: String?
    let previous: String?
    let total: Int
    let offset: Int
}

struct PlaylistItem: Codable {
    let track: AudioTrack?
    let added_at: String
}
