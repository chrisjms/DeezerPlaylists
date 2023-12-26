//
//  FakePlaylistRepository.swift
//  DeezerPlaylistsTests
//
//  Created by Christopher James on 26/12/2023.
//

@testable import DeezerPlaylists
import Combine
import XCTest

class FakePlaylistRepository: PlaylistRepository {
    
    let expectation = XCTestExpectation(description: "fetch playlist called")

    var isFetchPlaylistsCalled: Bool = false
    
    var playlists: [Playlist] = [
        Playlist.fake(id: "id1", title: "first title"),
        Playlist.fake(id: "id2", title: "a second title"),
        Playlist.fake(id: "id3", title: "third title")
    ]
    
    private let playlistsPub = CurrentValueSubject<[Playlist], Error>([])

    func fetchPlaylists() async throws {
        isFetchPlaylistsCalled = true
        expectation.fulfill()
    }
    
    func observePlaylists() -> AnyPublisher<[Playlist], Error> {
        playlistsPub.send(playlists)
        return playlistsPub.eraseToAnyPublisher()
    }
    
}
