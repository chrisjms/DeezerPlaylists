//
//  PlaylistViewModel.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation
import Combine

struct PlaylistItem {
    let id: String
    let title: String
    let description: String
    let pictureSmall: URL?
    let pictureMedium: URL?
}

@MainActor
class PlaylistViewModel: ObservableObject {
    
    private let playlistRepository: PlaylistRepository
    
    @Published private (set) var playlists = [PlaylistItem]()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(playlistRepository: PlaylistRepository) {
        self.playlistRepository = playlistRepository
        
        playlistRepository.observePlaylists()
            .sink { _ in
            } receiveValue: { [weak self] playlists in
                self?.playlists = playlists
                    .map { playlist in PlaylistItem(playlist) }
                    .sorted(by: { playlist1, playlist2 in
                        playlist1.title.localizedStandardCompare(playlist2.title) == .orderedAscending
                    })
            }
            .store(in: &cancellables)
        
        Task {
            await fetchPlaylists()
        }
    }
    
    func fetchPlaylists() async {
        do {
            try await playlistRepository.fetchPlaylists()
        } catch(let error) {
            print("error fetching playlists \(error)")
        }
    }
}

extension PlaylistItem {
    init(_ playlist: Playlist) {
        self.id = playlist.id
        self.title = playlist.title
        self.description = playlist.description
        self.pictureSmall = playlist.pictureSmall
        self.pictureMedium = playlist.pictureMedium
    }
}
