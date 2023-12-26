//
//  FakePlaylist.swift
//  DeezerPlaylistsTests
//
//  Created by Christopher James on 26/12/2023.
//

import Foundation
@testable import DeezerPlaylists

extension Playlist {
    static func fake(
        id: String,
        title: String = "",
        duration: String = "",
        nbTracks: String = "",
        picture: URL? = nil
    ) -> Playlist {
        return Playlist(
            id: id,
            title: title,
            duration: duration,
            nbTracks: nbTracks,
            picture: picture
        )
    }
}
