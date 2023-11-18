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
        VStack {
            Text("Hello playlists")
            Text("I have \(viewModel.playlists.count) playlists in my Deezer account")
        }
    }
}

private struct PlaylistsView: View {
    var body: some View {
        Text("Hello playlists")
    }
}

#Preview {
    PlaylistsView()
}
