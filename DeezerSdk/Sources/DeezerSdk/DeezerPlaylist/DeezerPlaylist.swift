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
    public let picture_small: URL
    public let is_loved_track: Bool
    
    public init(
        id: Int,
        title: String,
        duration: Int,
        nb_tracks: Int,
        picture_small: URL,
        is_loved_track: Bool
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.nb_tracks = nb_tracks
        self.picture_small = picture_small
        self.is_loved_track = is_loved_track
    }
    
}
