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
    func observePlaylist(playlistId: String) -> AnyPublisher<Playlist?, Error>
    func observeTracks(playlistId: String) -> AnyPublisher<[Track], Error>
    func fetchTracks(playlistId: String) async throws
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
        let deezerPlaylists = try await playlistClient.getPlaylists(userId: "5610413841")
        let deezerTracks = try await self.fetchTracks(playlists: deezerPlaylists)
        try await database.dbWriter.write { db in
            try deezerPlaylists.forEach { deezerPlaylist in
                try PlaylistDb(
                    id: deezerPlaylist.id.toString(),
                    title: deezerPlaylist.title,
                    duration: deezerPlaylist.duration.toString(),
                    nbTracks: deezerPlaylist.nb_tracks.toString(),
                    pictureSmall: deezerPlaylist.picture_small.absoluteString,
                    pictureMedium: deezerPlaylist.picture_medium.absoluteString
                ).upsert(db)
                guard let tracksForPlaylist = deezerTracks[deezerPlaylist.id] else { return }
                try tracksForPlaylist.forEach { track in
                    try TrackDb(
                        id: track.id.toString(),
                        playlistId: deezerPlaylist.id.toString(),
                        title: track.title_short,
                        duration: String(track.duration),
                        artistName: track.artist.name
                    ).upsert(db)
                }
            }
        }
    }
    
    func fetchTracks(playlistId: String) async throws {
        guard let playlistIdInt = Int(playlistId) else { return }
        let tracks = try await self.playlistClient.getTracks(playlistId: playlistIdInt)
        try await database.dbWriter.write { db in
            try tracks.forEach { track in
                try TrackDb(
                    id: track.id.toString(),
                    playlistId: playlistId,
                    title: track.title_short,
                    duration: String(track.duration),
                    artistName: track.artist.name
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
    
    func observePlaylist(playlistId: String) -> AnyPublisher<Playlist?, Error> {
        let observationScheduler: ValueObservationScheduler = .async(onQueue: DispatchQueue.global())
        
        let playlistPub = ValueObservation.tracking { db in
            try PlaylistDb
                .fetchOne(db, id: playlistId)
        }.publisher(in: database.dbWriter, scheduling: observationScheduler)
        
        return playlistPub
            .map { playlistDb in
                guard let playlistDb else { return nil }
                return Playlist(playlistDb)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func observeTracks(playlistId: String) -> AnyPublisher<[Track], Error> {
        let observationScheduler: ValueObservationScheduler = .async(onQueue: DispatchQueue.global())
        
        let tracksPub = ValueObservation.tracking { db in
            try TrackDb
                .all()
                .filter(playlistId: playlistId)
                .fetchAll(db)
        }.publisher(in: database.dbWriter, scheduling: observationScheduler)
        
        return tracksPub
            .map { tracksDb in
                return tracksDb.map { trackDb in
                    return Track(trackDb)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func fetchTracks(playlists: [DeezerPlaylist]) async throws -> [Int: [DeezerTrack]] {
        return try await withThrowingTaskGroup(of: (Int, [DeezerTrack]).self, returning: [Int: [DeezerTrack]].self) { taskGroup in
            for playlistId in playlists.map(\.id) {
                taskGroup.addTask {
                    let tracks = try await self.playlistClient.getTracks(playlistId: playlistId)
                    return (playlistId, tracks)
                }
            }
            var tracks: [Int: [DeezerTrack]] = [:]
            
            while let tracksWithPlaylistId = try await taskGroup.next() {
                tracks[tracksWithPlaylistId.0] = tracksWithPlaylistId.1
            }
            return tracks
        }
    }
}
