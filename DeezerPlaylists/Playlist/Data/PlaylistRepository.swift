//
//  PlaylistRepository.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation
import DeezerSdk

protocol PlaylistRepository {
    func fetchUserPlaylists() async throws -> [Playlist]
}

class PlaylistHttpRepository: PlaylistRepository {
    
    private let playlistClient: PlaylistClient
    
    init(playlistClient: PlaylistClient) {
        self.playlistClient = playlistClient
    }
    
    func fetchUserPlaylists() async throws -> [Playlist] {
        let deezerPlaylists = try await playlistClient.getUserPlaylists(userId: "5610413841")
        return deezerPlaylists.map { deezerPlaylist in
            Playlist(
                id: String(deezerPlaylist.id),
                title: deezerPlaylist.title,
                duration: deezerPlaylist.duration,
                nbtracks: deezerPlaylist.nb_tracks
            )
        }
    }
}
