//
//  PlaylistDb.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import GRDB

struct PlaylistDb: Identifiable, Codable, PersistableRecord, FetchableRecord, Equatable {
    let id: String
    let title: String
    let duration: String
    let nbTracks: String
    let pictureSmall: String
    let pictureMedium: String

    fileprivate enum Colums {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let duration = Column(CodingKeys.duration)
        static let nbTracks = Column(CodingKeys.nbTracks)
        static let pictureSmall = Column(CodingKeys.pictureSmall)
        static let pictureMedium = Column(CodingKeys.pictureMedium)
    }
}
