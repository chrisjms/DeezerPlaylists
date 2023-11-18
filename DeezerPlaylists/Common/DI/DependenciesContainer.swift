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
    
    func makePlaylistViewModel() -> PlaylistViewModel {
        return PlaylistViewModel(playlistRepository: PlaylistHttpRepository(playlistClient: deezerSdk.playlistClient))
    }
    
}
