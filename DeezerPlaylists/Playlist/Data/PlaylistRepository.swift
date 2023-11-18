//
//  PlaylistRepository.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation
import DeezerSdk

protocol PlaylistRepository {
    func fetchUserPlaylists() async throws
}

class PlaylistHttpRepository: PlaylistRepository {
    
    private let playlistClient: PlaylistClient
    
    init(playlistClient: PlaylistClient) {
        self.playlistClient = playlistClient
    }
    
    func fetchUserPlaylists() async throws {
        let playlists = try await playlistClient.getUserPlaylists(userId: "5610413841")
        print("playlists: \(playlists)")
    }
}
