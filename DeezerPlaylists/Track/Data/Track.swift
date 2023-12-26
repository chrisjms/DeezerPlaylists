//
//  Track.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 26/12/2023.
//

import Foundation

struct Track {
    let id: String
    let title: String
    let duration: String
    let artistName: String
}

extension Track {
    init(_ trackDb: TrackDb) {
        self.id = trackDb.id
        self.title = trackDb.title
        self.duration = trackDb.duration
        self.artistName = trackDb.artistName
    }
}
