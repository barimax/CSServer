//
//  CSLogger.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 17.06.20.
//

import Foundation
import CSCoreView
import PerfectCRUD
import PerfectMySQL

class CSLogger {
    let mysql = MySQL()
    init() throws {
        let connected = mysql.connect(
            host: CSServer.configuration!.host,
            user: CSServer.configuration!.username,
            password: CSServer.configuration!.password,
            db: nil,
            port: UInt32(CSServer.configuration!.port)
        )
        guard connected else {
            throw CSLoggerError.databaseConnectionError
        }
    }
    func log(database dbName: String, log: CSLogEntity) throws {
        let selectedDatabase = self.mysql.selectDatabase(named: dbName)
        if selectedDatabase {
            let db = Database(configuration: MySQLDatabaseConfiguration(connection: self.mysql))
            try db.table(CSLogEntity.self).insert(log)
        }else{
            throw CSLoggerError.databaseSelectError
        }
    }
    func create(database dbName: String) throws {
        let selectedDatabase = self.mysql.selectDatabase(named: dbName)
        if selectedDatabase {
            let db = Database(configuration: MySQLDatabaseConfiguration(connection: self.mysql))
            try db.create(CSLogEntity.self)
        }else{
            throw CSLoggerError.databaseSelectError
        }
    }
}

enum CSLoggerError: Error {
    case databaseConnectionError
    case databaseSelectError
}
