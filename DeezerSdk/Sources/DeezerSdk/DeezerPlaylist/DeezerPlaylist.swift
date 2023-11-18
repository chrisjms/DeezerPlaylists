//
//  Playlist.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

public struct DeezerPlaylist: Codable {
    public let id: Int
    public let title: String
    public let duration: Int
    public let nb_tracks: Int
    
    public init(id: Int, title: String, duration: Int, nb_tracks: Int) {
        self.id = id
        self.title = title
        self.duration = duration
        self.nb_tracks = nb_tracks
    }
    
}
