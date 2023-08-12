//
//  NewReleasesResponse.swift
//  Spotify
//
//  Created by Carson Gross on 6/30/23.
//

import Foundation

struct NewReleasesResponse: Codable {
    let albums: AlbumsResponse
}

struct AlbumsResponse: Codable {
    let items: [Album]
}

struct Album: Codable, Equatable {
    static func == (lhs: Album, rhs: Album) -> Bool {
        lhs.id == rhs.id
    }
    
    let album_type: String
    let available_markets: [String]
    let id: String
    var images: [APIImage]
    let name: String
    let release_date: String
    let total_tracks: Int
    let artists: [Artist]
    let external_urls: [String: String]
}
