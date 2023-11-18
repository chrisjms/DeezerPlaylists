//
//  File.swift
//  
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

public class DeezerSdk {
    
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    public init() {
        
    }
    
    struct HttpError: Error {
        let code: Int
        let response: HTTPURLResponse
        let data: Data?
        
        init(response: HTTPURLResponse, data: Data?) {
            self.code = response.statusCode
            self.response = response
            self.data = data
        }
    }
    
    struct DecodingError: Error {
        let rawError: Error
        let data: Data
    }
    
    private lazy var httpClient = HttpClient(
        baseUrl: "https://api.deezer.com",
        jsonEncoder: jsonEncoder,
        jsonDecoder: jsonDecoder,
        urlSession: createUrlSession()
    )
    
    public lazy var playlistClient: PlaylistClient = PlaylistHttpClient(httpClient: httpClient)
    
    private func createUrlSession() -> URLSession {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }
}
