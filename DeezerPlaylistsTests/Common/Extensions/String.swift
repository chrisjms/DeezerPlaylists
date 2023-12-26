//
//  String.swift
//  DeezerPlaylistsTests
//
//  Created by Christopher James on 26/12/2023.
//

@testable import DeezerPlaylists
import XCTest

final class StringExtensionTests: XCTest {
    
    func test_toUrl() throws {
        let myString = "www.anurl.com"
        let myUrl = try XCTUnwrap(myString.toUrl())
        XCTAssertEqual(myUrl.absoluteString, "www.anurl.com")
    }
    
}
