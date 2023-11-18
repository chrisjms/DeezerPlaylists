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
    
    @Published private (set) var playlists = [Playlist]()
    
    init(playlistRepository: PlaylistRepository) {
        self.playlistRepository = playlistRepository
        Task {
            do {
                self.playlists = try await playlistRepository.fetchUserPlaylists()
            } catch(let error) {
                print("error fetching playlists \(error)")
            }
        }
    }
    
}
