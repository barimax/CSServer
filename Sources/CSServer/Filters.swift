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
    
    filters.append(["type":"request","priority":"high","name":AuthorizationFilter(secret: CSServer.configuration!.secret).filter])
    return filters
}
