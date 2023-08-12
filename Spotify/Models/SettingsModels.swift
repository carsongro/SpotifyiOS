//
//  SettingsModels.swift
//  Spotify
//
//  Created by Carson Gross on 6/29/23.
//

import Foundation

struct Section {
    let title: String
    let options: [Option]
}

struct Option {
    let title: String
    let handler: () -> Void
}
