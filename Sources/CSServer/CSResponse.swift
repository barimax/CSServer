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
    var viewType: CSViewType
}

public enum CSResponseType: String, Encodable {
    case json
    case string
    case number
    case bool
    case jsonString
}

public extension HTTPResponse {
    func sendResponse<T: Encodable>(body b: T, responseType rt: CSResponseType, viewType vt: CSViewType = .entityView, statusCode: HTTPResponseStatus = .ok) {
        let response: CSResponse = CSResponse(body: b, type: rt, viewType: vt)
        do {
            try self.setBody(json: response)
            self.completed(status: statusCode)
        }catch{
            self.completed(status: .internalServerError)
        }
    }
}
