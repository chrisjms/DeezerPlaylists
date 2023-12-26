//
//  File.swift
//  
//
//  Created by Christopher James on 26/12/2023.
//

import Foundation

public struct DeezerTrack: Codable {
    public let id: Int
    public let title_short: String
    public let duration: Int
    public let artist: DeezerArtist
    
    public init(
        id: Int,
        title_short: String,
        duration: Int,
        artist: DeezerArtist
    ) {
        self.id = id
        self.title_short = title_short
        self.duration = duration
        self.artist = artist
    }
}

public struct DeezerArtist: Codable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}
