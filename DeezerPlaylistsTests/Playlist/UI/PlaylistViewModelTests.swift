//
//  PlaylistViewModelTests.swift
//  DeezerPlaylistsTests
//
//  Created by Christopher James on 26/12/2023.
//

import Foundation
@testable import DeezerPlaylists
import XCTest
import Combine
import GRDB

@MainActor
final class PlaylistViewModelTests: XCTestCase {
    
    private var viewModel: PlaylistViewModel!
    private var playlistRepository: FakePlaylistRepository = FakePlaylistRepository()
    
    @MainActor
    override func setUp() async throws {
        self.viewModel = PlaylistViewModel(playlistRepository: playlistRepository)
    }
    
    func test_initialState() throws {
        let playlistsPub = viewModel.$playlists
        let playlistsRecorder = playlistsPub.record()
        let playlists = try wait(for: playlistsRecorder.next(), timeout: 1)
        wait(for: [playlistRepository.expectation], timeout: 1)
        XCTAssertEqual(playlists.count, 3)
        XCTAssertEqual(playlists.first?.id, "id2")
        XCTAssertNotNil(playlists.first(where: { $0.id == "id2"} ))
        XCTAssertNotNil(playlists.last?.id, "id3")
        XCTAssertTrue(playlistRepository.isFetchPlaylistsCalled)
    }
    
    func test_fetchPlaylists() async throws {
        await viewModel.fetchPlaylists()
        let playlistsPub = viewModel.$playlists
        let playlistsRecorder = playlistsPub.record()
        let playlists = try wait(for: playlistsRecorder.next(), timeout: 1)
        XCTAssertEqual(playlists.count, 3)
        XCTAssertEqual(playlists.first?.id, "id2")
        XCTAssertNotNil(playlists.first(where: { $0.id == "id2"} ))
        XCTAssertNotNil(playlists.last?.id, "id3")
        XCTAssertTrue(playlistRepository.isFetchPlaylistsCalled)
    }
}
