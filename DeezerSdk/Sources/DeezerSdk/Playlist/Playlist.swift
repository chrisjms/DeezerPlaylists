//
//  Playlist.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

public struct Playlist: Codable {
    public let id: Int
    public let title: String
    public let description: String
    public let duration: Int
    public let nb_tracks: Int
}
