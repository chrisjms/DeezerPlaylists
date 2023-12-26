//
//  PlaylistView.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import SwiftUI

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
    let playlists: [PlaylistItem]
    let onPullToRefresh: () async -> Void
    var body: some View {
        NavigationStack {
            List(playlists, id: \.id) { playlist in
                PlaylistCard(playlist: playlist)
                    .listRowSeparator(.hidden)
            }
            .refreshable {
                await onPullToRefresh()
            }
            .listStyle(.inset)
            .navigationTitle("Playlists")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct PlaylistCard: View {
    let playlist: PlaylistItem
    var body: some View {
        HStack {
            if let picture = playlist.picture {
                AsyncImage(url: playlist.picture)
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
                picture: nil
            ),
            PlaylistItem(
                id: "id2",
                title: "playlist 2",
                description: "24 titres et 200 min",
                picture: nil
            ),
            PlaylistItem(
                id: "id3",
                title: "playlist 3",
                description: "13 titres et 29 min",
                picture: nil
            ),
            PlaylistItem(
                id: "id4",
                title: "playlist 4",
                description: "10 titres et 99 min",
                picture: nil
            )
        ],
        onPullToRefresh: {}
    )
}
