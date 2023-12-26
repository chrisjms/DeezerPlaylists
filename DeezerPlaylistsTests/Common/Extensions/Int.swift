//
//  Int.swift
//  DeezerPlaylistsTests
//
//  Created by Christopher James on 26/12/2023.
//

@testable import DeezerPlaylists
import XCTest

final class IntExtensionTests: XCTest {
    
    func test_toString() {
        let myInt = 45
        let myString = myInt.toString()
        XCTAssertEqual(myString, "45")
    }
    
}
