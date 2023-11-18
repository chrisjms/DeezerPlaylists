//
//  PlaylistClient.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

public protocol PlaylistClient {
    func GetUserPlaylists(userId: String) async throws -> [Playlist]
    func GetPlaylistinfos() async throws
    func GetPlaylistTracks() async throws
}

internal class PlaylistHttpClient: PlaylistClient {
    
    private let httpClient: HttpClient

    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }
    
    func GetUserPlaylists(userId: String) async throws -> [Playlist] {
        return try await httpClient.get("/user/\(userId)/playlists")
    }
    
    func GetPlaylistinfos() async throws {
        
    }
    
    func GetPlaylistTracks() async throws {
        
    }
}
