//
//  RecommendationsResponse.swift
//  Spotify
//
//  Created by Carson Gross on 6/30/23.
//

import Foundation

struct RecommendationsResponse: Codable {
    let tracks: [AudioTrack]
}
