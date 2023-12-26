//
//  AppDatabase.swift
//  DeezerPlaylists
//
//  Created by Christopher James on 18/11/2023.
//

import Foundation
import GRDB

class AppDatabase {
    
    let dbWriter: DatabaseWriter
    
    convenience init() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            let databaseURL = directoryURL.appendingPathComponent("5610413841.sqlite")
            let dbQueue = try DatabaseQueue(path: databaseURL.path)
            try self.init(dbQueue)
        } catch {
            fatalError("Could not create the database \(error)")
        }
    }
    
    init(_ databaseQueue: DatabaseQueue) throws {
        self.dbWriter = databaseQueue
        try migrator.migrate(databaseQueue)
    }
}

extension AppDatabase {
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        // Speed up development by nuking the database when migrations change
        // See <https://swiftpackageindex.com/groue/grdb.swift/documentation/grdb/migrations>
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        migrator.registerMigration("initial") { db in
            try db.create(table: "playlistDb") { t in
                t.column("id", .text)
                    .notNull()
                    .primaryKey()
                t.column("title", .text)
                t.column("duration", .text)
                t.column("nbTracks", .text)
                t.column("pictureSmall", .text)
                t.column("pictureMedium", .text)
            }
            
            try db.create(table: "trackDb") { t in
                t.column("id", .text)
                    .notNull()
                    .primaryKey()
                t.column("playlistId", .text)
                t.column("title", .text)
                t.column("duration", .text)
                t.column("artistName", .text)
            }
        }
        
        return migrator
    }
}
