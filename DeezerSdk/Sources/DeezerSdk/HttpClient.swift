//
//  HttpClient.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

class HttpClient {
    
    struct UnknownError: Error { }
    
    private let urlSession: URLSession
    private let baseUrl: String
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    
    init(
        baseUrl: String,
        jsonEncoder: JSONEncoder,
        jsonDecoder: JSONDecoder,
        urlSession: URLSession
    ) {
        self.baseUrl = baseUrl
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
        self.urlSession = urlSession
    }
    
    func postRequest<E: Encodable, D: Decodable>(
        _ url: String,
        body: E,
        queryParameters: [String: String] = [:],
        completion: @escaping (Result<D, Error>) -> Void
    ) {
        do {
            let request = buildJsonRequest(url, httpMethod: "POST", queryParameters: queryParameters)
            let json = try jsonEncoder.encode(body)
            urlSession.uploadTask(with: request, from: json) { data, response, error in
                self.handleJsonResponse(data: data, response: response, error: error, completion: completion)
            }.resume()
        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
        }
    }
    
    private func validateResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> Result<Data, Error> {
        if let error = error as? URLError {
            return .failure(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            fatalError("response from request isn't HTTPURLResponse")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Http error: \(httpResponse.statusCode) \(String(describing: httpResponse.url))")
            if let data = data, let stringData = String(data: data, encoding: .utf8) {
                print(stringData)
            }
        
            return Result.failure(DeezerSdk.HttpError(response: httpResponse, data: data))
        }
        
        if let data = data {
            return .success(data)
        } else {
            return .failure(UnknownError())
        }
    }
    
    private func handleJsonResponse<D: Decodable>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<D, Error>) -> Void
    ) {
        
        let responseValidated = validateResponse(data: data, response: response, error: error)
        
        switch responseValidated {
        case .failure(let error):
            DispatchQueue.main.async { completion(.failure(error)) }
        case .success(let data):
            do {
                let decodedResult = try self.jsonDecoder.decode(D.self, from: data)
                DispatchQueue.main.async { completion(.success(decodedResult)) }
            } catch {
                print("Error decoding json \(error)")
                DispatchQueue.main.async {
                    completion(.failure(DeezerSdk.DecodingError(rawError: error, data: data)))
                }
            }
        }
    }

    func get<D: Decodable>(_ url: String, queryParameters: [String: String] = [:]) async throws -> D {
        let request = buildJsonRequest(url, httpMethod: "GET", queryParameters: queryParameters)
        let (data, response) = try await urlSession.data(for: request)
        return try await handleJsonResponse(data: data, response: response)
    }
    
    func getBinary(_ url: String, queryParameters: [String: String] = [:]) async throws -> Data {
        let request = buildJsonRequest(url, httpMethod: "GET", queryParameters: queryParameters)
        let (data, response) = try await urlSession.data(for: request)
        try validateResponseOrThrow(data: data, response: response)
        return data
    }
    
    func post<E: Encodable, D: Decodable>(
        _ url: String,
        body: E,
        queryParameters: [String: String] = [:]
    ) async throws -> D {
        let request = buildJsonRequest(url, httpMethod: "POST", queryParameters: queryParameters)
        let json = try jsonEncoder.encode(body)
        let (data, response) = try await urlSession.upload(for: request, from: json)
        return try await handleJsonResponse(data: data, response: response)
    }
    
    func post<E: Encodable>(
        _ url: String,
        body: E,
        queryParameters: [String: String] = [:]
    ) async throws {
        let request = buildJsonRequest(url, httpMethod: "POST", queryParameters: queryParameters)
        let json = try jsonEncoder.encode(body)
        let (data, response) = try await urlSession.upload(for: request, from: json)
        try validateResponseOrThrow(data: data, response: response)
    }
    
    /// Returns: The location of the downloaded file as a URL.
    /// It is downloaded at the location decided by UrlSession.download, and so if you want to preserve the file, you must copy or move it from this location.
    func downloadFile(_ url: String) async throws -> URL {
        let request = buildRequest(url, httpMethod: "GET")
        let (localUrl, response) = try await urlSession.download(for: request)
        try validateResponseOrThrow(data: nil, response: response)
        return localUrl
    }
    
    func uploadFile(
        _ url: String,
        fileUrl: URL,
        queryParameters: [String: String] = [:]
    ) async throws {
        let request = buildRequest(url, httpMethod: "POST", queryParameters: queryParameters)
        let (data, response) = try await urlSession.upload(for: request, fromFile: fileUrl)
        try validateResponseOrThrow(data: data, response: response)
    }

    private func handleJsonResponse<D: Decodable>(data: Data, response: URLResponse) async throws -> D {
        try validateResponseOrThrow(data: data, response: response)
        
        do {
            return try self.jsonDecoder.decode(D.self, from: data)
        } catch {
            throw DeezerSdk.DecodingError(rawError: error, data: data)
        }
    }
    
    private func validateResponseOrThrow(data: Data?, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            fatalError("response from request isn't HTTPURLResponse")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Http error: \(httpResponse.statusCode) \(String(describing: httpResponse.url))")
            throw DeezerSdk.HttpError(response: httpResponse, data: data)
        }
    }
    
    private func buildRequest(
        _ path: String,
        httpMethod: String,
        queryParameters: [String: String] = [:]
    ) -> URLRequest {
        let url = buildUrl(path, queryParameters: queryParameters)
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        return request
    }
    
    private func buildJsonRequest(
        _ path: String,
        httpMethod: String,
        accessToken: String? = nil,
        queryParameters: [String: String] = [:]
    ) -> URLRequest {
        var request = buildRequest(path, httpMethod: httpMethod, queryParameters: queryParameters)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    func buildUrl(_ path: String, queryParameters: [String: String] = [:]) -> URL {
        var urlComponents = URLComponents(string: baseUrl + path)!
        if !queryParameters.isEmpty {
            let queryItems = queryParameters.map { (key: String, value: String) in
                URLQueryItem(name: key, value: value)
            }
            urlComponents.queryItems = queryItems
        }
        return urlComponents.url!
    }
}
