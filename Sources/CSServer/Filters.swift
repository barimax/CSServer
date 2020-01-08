//
//  Filters.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 7.11.19.
//

import Foundation
import PerfectHTTP

func filters() -> [[String: Any]] {
    
    var filters: [[String: Any]] = [[String: Any]]()
//    let compression = try? PerfectHTTPServer.HTTPFilter.contentCompression(data: ["compressTypes":["text/css"]])
//    filters.append(["type":"request","priority":"high","name":FilterMappingFiles.filterAPIRequest])
//     filters.append(["type":"request","priority":"high","name":HttpToHTTPs.filterAPIRequest])
//    filters.append(["type":"response","priority":"high","name":PerfectHTTPServer.HTTPFilter.contentCompression])
    
//    filters.append(["type":"request","priority":"high","name":RequestLogger.filterAPIRequest])
//    filters.append(["type":"response","priority":"low","name":RequestLogger.filterAPIResponse])
//
//    // added for sessions
//    filters.append(["type":"request","priority":"high","name":SessionMySQLFilter.filterAPIRequest])
//    filters.append(["type":"response","priority":"high","name":SessionMySQLFilter.filterAPIResponse])
    
    filters.append(["type":"request","priority":"high","name":AuthorizationFilter.authFilter])
    return filters
}

public struct CSFilters {
    private static var requestFilters: [(HTTPRequestFilter, HTTPFilterPriority)] = []
    private static var responseFilters: [(HTTPResponseFilter, HTTPFilterPriority)] = []
    
    public static func add(requestFilter filter: (HTTPRequestFilter, HTTPFilterPriority)){
        Self.requestFilters.append(filter)
    }
    public static func add(responseFilter filter: (HTTPResponseFilter, HTTPFilterPriority)){
        Self.responseFilters.append(filter)
    }
    public static func getRequestFilters() -> [(HTTPRequestFilter, HTTPFilterPriority)] {
        Self.requestFilters
    }
    public static func getResponseFilters() -> [(HTTPResponseFilter, HTTPFilterPriority)]  {
        Self.responseFilters
    }
}
extension CSFilters {
    static func load() {
        Self.requestFilters.append((AuthorizationFilter(), .high))
        Self.responseFilters.append((SessionResponseFilter(), .high))
    }
}
