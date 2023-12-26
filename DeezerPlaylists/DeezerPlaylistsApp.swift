//
//  DeezerPlaylistsApp.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import SwiftUI
import UIPilot

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
    @StateObject var appRouter = AppRouter(initial: .playlist)

    init() {
        _dependenciesContainer = StateObject(wrappedValue: DependenciesContainer())
    }
    
    var body: some View {
        UIPilotHost(appRouter.pilot) { route in
            switch route {
            case .playlist:
                PlaylistsScreen(viewModel: dependenciesContainer.makePlaylistViewModel())
            case .track(let playlistId):
                TrackScreen(viewModel: dependenciesContainer.makeTrackViewModel(playlistId: playlistId))
            }
        }
        .environmentObject(appRouter)
        .navigationBarTitleDisplayMode(.inline)
    }
}

class AppRouter: ObservableObject {
    @Published var pilot: UIPilot<AppRoute>
    
    init(initial: AppRoute) {
        self.pilot = UIPilot(initial: initial)
    }
    
    func push(_ route: AppRoute) {
        pilot.push(route)
    }
    
    func pop() {
        pilot.pop()
    }
}

enum AppRoute: Equatable {
    case playlist
    case track(playlistId: String)
}
