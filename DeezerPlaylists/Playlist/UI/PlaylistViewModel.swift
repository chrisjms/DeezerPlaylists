//
//  PlaylistViewModel.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

@MainActor
class PlaylistViewModel: ObservableObject {
    
    private let playlistRepository: PlaylistRepository
    
    init(playlistRepository: PlaylistRepository) {
        self.playlistRepository = playlistRepository
        Task {
            do {
                try await playlistRepository.fetchUserPlaylists()
            } catch(let error) {
                print("error fetching playlists \(error)")
            }
        }
    }
    
}
