//
//  TrackViewModel.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 26/12/2023.
//

import Foundation
import Combine

@MainActor
class TrackViewModel: ObservableObject {
    
    private let playlistId: String
    private let playlistRepository: PlaylistRepository
    
    @Published private (set) var tracks = [Track]()
    
    private var cancellables = Set<AnyCancellable>()

    init(
        playlistId: String,
        playlistRepository: PlaylistRepository
    ) {
        
        self.playlistId = playlistId
        self.playlistRepository = playlistRepository
        
        playlistRepository.observeTracks(playlistId: playlistId)
            .sink { _ in
            } receiveValue: { [weak self] tracks in
                self?.tracks = tracks
            }
            .store(in: &cancellables)
    }
    
    func onPullToRefresh() async {
        do {
            try await playlistRepository.fetchTracks(playlistId: playlistId)
        } catch {
            print("Error fetching tracks")
        }
    }
}
