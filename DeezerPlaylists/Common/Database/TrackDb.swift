//
//  TrackDb.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 26/12/2023.
//

import GRDB

struct TrackDb: Identifiable, Codable, PersistableRecord, FetchableRecord, Equatable {
    let id: String
    let playlistId: String
    let title: String
    let duration: String
    let artistName: String
    
    fileprivate enum Colums {
        static let id = Column(CodingKeys.id)
        static let playlistId = Column(CodingKeys.playlistId)
        static let title = Column(CodingKeys.title)
        static let duration = Column(CodingKeys.duration)
        static let artistName = Column(CodingKeys.artistName)
    }
}

extension DerivableRequest<TrackDb> {
    func filter(playlistId: String) -> Self {
        filter(TrackDb.Colums.playlistId == playlistId)
    }
}
