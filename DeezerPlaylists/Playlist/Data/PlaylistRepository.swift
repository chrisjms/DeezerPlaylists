//
//  PlaylistRepository.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation
import DeezerSdk
import Combine
import GRDB

protocol PlaylistRepository {
    func fetchPlaylists() async throws
    func observePlaylists() -> AnyPublisher<[Playlist], Error>
}

class PlaylistHttpRepository: PlaylistRepository {
    
    private let playlistClient: PlaylistClient
    private let database: AppDatabase
    
    init(
        playlistClient: PlaylistClient,
        database: AppDatabase
    ) {
        self.playlistClient = playlistClient
        self.database = database
    }
    
    func fetchPlaylists() async throws {
        let deezerPlaylists = try await playlistClient.getUserPlaylists(userId: "5610413841")
        try await database.dbWriter.write { db in
            try deezerPlaylists.forEach { deezerPlaylist in
                try PlaylistDb(
                    id: String(deezerPlaylist.id),
                    title: deezerPlaylist.title,
                    duration: deezerPlaylist.duration.toString(),
                    nbTracks: deezerPlaylist.nb_tracks.toString(),
                    picture: deezerPlaylist.picture_small.absoluteString
                ).upsert(db)
            }
        }
    }
    
    func observePlaylists() -> AnyPublisher<[Playlist], Error> {
        let observationScheduler: ValueObservationScheduler = .async(onQueue: DispatchQueue.global())
        
        let playlistsPub = ValueObservation.tracking { db in
            try PlaylistDb
                .all()
                .fetchAll(db)
        }.publisher(in: database.dbWriter, scheduling: observationScheduler)
        
        return playlistsPub
            .map { playlistsDb in
                return playlistsDb.map { playlistDb in
                    return Playlist(playlistDb)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
