//
//  String.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 26/12/2023.
//

import Foundation

extension String {
    func toUrl() -> URL? {
        return URL(string: self)
    }
}
