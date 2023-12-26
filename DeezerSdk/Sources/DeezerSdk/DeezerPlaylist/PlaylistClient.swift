//
//  PlaylistClient.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

public protocol PlaylistClient {
    func getPlaylists(userId: String) async throws -> [DeezerPlaylist]
    func getPlaylistinfos() async throws
    func getTracks(playlistId: Int) async throws -> [DeezerTrack]
}

internal class PlaylistHttpClient: PlaylistClient {
    
    private let httpClient: HttpClient

    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }
    
    func getPlaylists(userId: String) async throws -> [DeezerPlaylist] {
        return try await searchAll { page, limit in
            let response: PaginatedResponse<DeezerPlaylist> = try await httpClient.get("/user/\(userId)/playlists")
            return response
        }
        .filter { !$0.is_loved_track }
    }
    
    func getPlaylistinfos() async throws {
        
    }
    
    func getTracks(playlistId: Int) async throws -> [DeezerTrack] {
        return try await searchAll { page, limit in
            let response: PaginatedResponse<DeezerTrack> = try await httpClient.get("/playlist/\(playlistId)/tracks")
            return response
        }
    }
}
