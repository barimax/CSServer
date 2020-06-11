//
//  Filters.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 7.11.19.
//

import Foundation
import PerfectHTTP
import PerfectHTTPServer

//func filters() -> [[String: Any]] {
//
//    var filters: [[String: Any]] = [[String: Any]]()
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
//
//    filters.append(["type":"request","priority":"high","name":AuthorizationFilter.authFilter])
//    return filters
//}

public struct CSFilters {
    private static var requestFilters: [(HTTPRequestFilter, HTTPFilterPriority)] = []
    private static var responseFilters: [(HTTPResponseFilter, HTTPFilterPriority)] = []
    
    public static func add(requestFilter filter: (HTTPRequestFilter, HTTPFilterPriority)){
        CSFilters.requestFilters.append(filter)
    }
    public static func add(responseFilter filter: (HTTPResponseFilter, HTTPFilterPriority)){
        CSFilters.responseFilters.append(filter)
    }
    public static func getRequestFilters() -> [(HTTPRequestFilter, HTTPFilterPriority)] {
        return CSFilters.requestFilters
    }
    public static func getResponseFilters() -> [(HTTPResponseFilter, HTTPFilterPriority)]  {
       return  CSFilters.responseFilters
    }
}
extension CSFilters {
    static func load() {
        CSFilters.requestFilters.append((AuthorizationFilter(), HTTPFilterPriority.high))
        CSFilters.responseFilters.append((SessionResponseFilter(), .high))
        CSFilters.responseFilters.append((try! PerfectHTTPServer.HTTPFilter.contentCompression(data: [:]),.high))
    }
}
