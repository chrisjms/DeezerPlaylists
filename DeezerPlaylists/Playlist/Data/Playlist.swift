//
//  Playlist.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

struct Playlist {
    let id: String
    let title: String
    let duration: String
    let nbTracks: String
    let picture: URL?
    
    var description: String {
        return nbTracks + " titres et " + duration + " min"
    }
}

extension Playlist {
    init(_ playlistDb: PlaylistDb) {
        self.id = playlistDb.id
        self.title = playlistDb.title
        self.duration = playlistDb.duration
        self.nbTracks = playlistDb.nbTracks
        self.picture = playlistDb.picture.toUrl()
    }
}
