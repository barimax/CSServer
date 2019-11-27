//
//  CSResponse.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 13.11.19.
//

import Foundation
import PerfectHTTP

public struct CSResponse<T: Encodable>: Encodable {
    let body: T
    let type: CSResponseType
}

public enum CSResponseType: String, Encodable {
    case json
    case string
    case number
    case bool
    case jsonString
}

public extension HTTPResponse {
    func sendResponse<T: Encodable>(body b: T, responseType rt: CSResponseType, statusCode: HTTPResponseStatus = .ok) {
        let response: CSResponse = CSResponse(body: b, type: rt)
        do {
            try self.setBody(json: response)
            self.completed(status: statusCode)
        }catch{
            self.completed(status: .internalServerError)
        }
    }
}
