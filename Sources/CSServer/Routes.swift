//
//  Routes.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 5.11.19.
//

import Foundation

func routes() -> [[String: Any]] {
    var routes: [[String: Any]] = [[String: Any]]()
    routes.append(["method":"get", "uri":"/**", "handler":AuthHandlers.loginForm])
    routes.append(["method":"post", "uri":"/registration", "handler":AuthHandlers.registration])
    routes.append(["method":"post", "uri":"/login", "handler":AuthHandlers.login])
    return routes
}
