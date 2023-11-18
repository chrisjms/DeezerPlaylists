//
//  PlaylistClient.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

public protocol PlaylistClient {
    func getUserPlaylists(userId: String) async throws -> [DeezerPlaylist]
    func getPlaylistinfos() async throws
    func getPlaylistTracks() async throws
}

internal class PlaylistHttpClient: PlaylistClient {
    
    private let httpClient: HttpClient

    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }
    
    func getUserPlaylists(userId: String) async throws -> [DeezerPlaylist] {
        return try await searchAll { page, limit in
            let response: PaginatedResponse<DeezerPlaylist> = try await httpClient.get("/user/\(userId)/playlists")
            return response
        }
    }
    
    func getPlaylistinfos() async throws {
        
    }
    
    func getPlaylistTracks() async throws {
        
    }
}
