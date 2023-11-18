//
//  DeezerPlaylistsApp.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import SwiftUI

@main
struct DeezerPlaylistsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    
    @StateObject private var dependenciesContainer: DependenciesContainer
    
    init() {
        _dependenciesContainer = StateObject(wrappedValue: DependenciesContainer())
    }
    
    var body: some View {
        PlaylistsScreen(viewModel: dependenciesContainer.makePlaylistViewModel())
    }
}
