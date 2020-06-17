//
//  CSLogEntity.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 17.06.20.
//

import Foundation
import CSCoreView

public struct CSLogEntity: Codable {
    let timestamp: Date = Date()
    let uri: String
    let description: String
    let user: String
    let result: CSLogResult
    let registerName: String
    let prevId: UInt64?
    
    public init(
        uri: String,
        description d: String,
        user u: String,
        result r: CSLogResult,
        registerName rn: String,
        prevId p: UInt64? = nil
        ) {
        self.uri = uri
        self.description = d
        self.user = u
        self.result = r
        self.registerName = rn
        self.prevId = p
    }
}
public enum CSLogResult: Int8, Codable {
    case success = 1
    case error = 0
}
