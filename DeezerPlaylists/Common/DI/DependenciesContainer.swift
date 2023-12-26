//
//  DependenciesContainer.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation
import DeezerSdk

@MainActor
class DependenciesContainer: ObservableObject {
    
    lazy var deezerSdk: DeezerSdk = DeezerSdk()
    
    lazy var database: AppDatabase = AppDatabase()
    
    lazy var playlistRepository = PlaylistHttpRepository(
        playlistClient: deezerSdk.playlistClient,
        database: database
    )
    
    func makePlaylistViewModel() -> PlaylistViewModel {
        return PlaylistViewModel(playlistRepository: playlistRepository)
    }
    
    func makeTrackViewModel(playlistId: String) -> TrackViewModel {
        return TrackViewModel(playlistId: playlistId, playlistRepository: playlistRepository)
    }
    
}
