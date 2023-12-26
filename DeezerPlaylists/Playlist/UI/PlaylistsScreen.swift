//
//  PlaylistView.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import SwiftUI
import UIPilot

struct PlaylistsScreen: View {
    @ObservedObject var viewModel: PlaylistViewModel
    var body: some View {
        PlaylistsView(
            playlists: viewModel.playlists,
            onPullToRefresh: viewModel.fetchPlaylists
        )
    }
}

private struct PlaylistsView: View {
    @EnvironmentObject var router: AppRouter
    
    let playlists: [PlaylistItem]
    let onPullToRefresh: () async -> Void
    var body: some View {
        List(playlists, id: \.id) { playlist in
            PlaylistCard(playlist: playlist)
                .listRowSeparator(.hidden)
                .background(
                    NavigationLink(
                        isActive: Binding(
                            get: { false },
                            set: { _ in
                                router.push(.track(playlistId: playlist.id))
                            }
                        ),
                        destination: {},
                        label: {}
                    ).opacity(0.0)
                )
        }
        .refreshable {
            await onPullToRefresh()
        }
        .listStyle(.inset)
        .uipNavigationTitle("Playlists")
    }
}

private struct PlaylistCard: View {
    let playlist: PlaylistItem
    var body: some View {
        HStack {
            if let picture = playlist.pictureSmall {
                AsyncImage(url: picture)
            }
            VStack(alignment: .leading) {
                Text(playlist.title)
                    .bold()
                Text(playlist.description)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    PlaylistsView(
        playlists: [
            PlaylistItem(
                id: "id1",
                title: "playlist 1",
                description: "20 titre et 245 min",
                pictureSmall: nil,
                pictureMedium: nil
            ),
            PlaylistItem(
                id: "id2",
                title: "playlist 2",
                description: "24 titres et 200 min",
                pictureSmall: nil,
                pictureMedium: nil
            ),
            PlaylistItem(
                id: "id3",
                title: "playlist 3",
                description: "13 titres et 29 min",
                pictureSmall: nil,
                pictureMedium: nil
            ),
            PlaylistItem(
                id: "id4",
                title: "playlist 4",
                description: "10 titres et 99 min",
                pictureSmall: nil,
                pictureMedium: nil
            )
        ],
        onPullToRefresh: {}
    )
}
