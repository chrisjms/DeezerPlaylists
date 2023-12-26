//
//  TrackScreen.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 26/12/2023.
//

import SwiftUI
import UIPilot

struct TrackScreen: View {
    @ObservedObject var viewModel: TrackViewModel
    var body: some View {
        TrackView(
            playlist: viewModel.playlist,
            tracks: viewModel.tracks,
            onPullToRefresh: viewModel.onPullToRefresh
        )
    }
}

private struct TrackView: View {
    let playlist: PlaylistItem?
    let tracks: [Track]
    let onPullToRefresh: () async -> ()
    var body: some View {
        VStack {
            if let playlist {
                HeaderTrack(playlist: playlist)
            }
            List(tracks, id: \.id) { track in
                TrackCard(track: track)
                    .listRowSeparator(.hidden)
            }
            .refreshable {
                await onPullToRefresh()
            }
            .listStyle(.inset)
            .uipNavigationTitle("Tracks")
        }
    }
}

private struct HeaderTrack: View {
    let playlist: PlaylistItem
    var body: some View {
        if let picture = playlist.pictureMedium {
            AsyncImage(url: picture)
        }
        Text(playlist.title)
        Text(playlist.description)
    }
}

private struct TrackCard: View {
    let track: Track
    var body: some View {
        VStack(alignment: .leading) {
            Text(track.title)
                .bold()
            HStack {
                Text(track.artistName)
                    .foregroundStyle(.gray)
                Text(track.duration)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    TrackView(
        playlist: PlaylistItem(
            id: "id1",
            title: "playlist 1",
            description: "20 titre et 245 min",
            pictureSmall: nil,
            pictureMedium: nil
        ),
        tracks: [
            Track(
                id: "id1",
                title: "track 1 title",
                duration: "20",
                artistName: "Jordan Belfort"
            ),
            Track(
                id: "id2",
                title: "track 2 title",
                duration: "10",
                artistName: "Jordan Belfort"
            ),
            Track(
                id: "id3",
                title: "track 3 title",
                duration: "32",
                artistName: "Jordan Belfort"
            ),
            Track(
                id: "id4",
                title: "track 4 title",
                duration: "10",
                artistName: "Jordan Belfort"
            )
        ],
        onPullToRefresh: {}
    )
}
