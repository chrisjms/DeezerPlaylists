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
    
    @StateObject private var dependenciesContainter: DependenciesContainer
    
    init() {
        _dependenciesContainter = StateObject(wrappedValue: DependenciesContainer())
    }
    
    var body: some View {
        EmptyView()
    }
}
