//
//  File.swift
//  
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation

struct PaginatedResponse<T: Decodable>: Decodable {
    let total: Int
    let data: [T]
}

func searchAll<T>(
    initialPage: Int = 1,
    limit: Int = 1000,
    request: (_ page: Int, _ limit: Int) async throws -> PaginatedResponse<T>
) async throws -> [T] {
    var page = initialPage
    var data = [T]()
    
    while true {
        let response: PaginatedResponse<T> = try await request(page, limit)
        data.append(contentsOf: response.data)
        if data.count >= response.total {
            break
        }
        if response.data.isEmpty {
            break
        }
        page += 1
    }
    return data
}
