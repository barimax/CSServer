//
//  Routes.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 5.11.19.
//

import Foundation
import PerfectHTTP

extension CSRoutes {
    static func load() {
        
        CSRoutes.add(method: .post, uri: "/registration", handler: AuthHandlers.registration, access: .guest)
        CSRoutes.add(method: .post, uri: "/login", handler: AuthHandlers.login, access: .guest)
        CSRoutes.add(method: .post, uri: "/resetPassword", handler: AuthHandlers.resetPassword, access: .guest)
        CSRoutes.add(method: .get, uri: "/emailValidation", handler: AuthHandlers.validateEmail, access: .guest)
        CSRoutes.add(method: .post, uri: "/resendValidationEmail", handler: AuthHandlers.resendVaidationEmail, access: .guest)
        CSRoutes.addToAuthUser(method: .post, uri: "/changePassword", handler: AuthHandlers.changePassword)
        CSRoutes.add(method: .get, uri: "/**", handler: AuthHandlers.loginForm, access: .guest)
    }
}

public struct CSRoutes {
    private static var routes: [CSRoute] = []
    
    public static func add(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: .guest))
    }
    public static func add(method: HTTPMethod, uri: String, handler: @escaping RequestHandler, access a: CSAccessLevel) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: a))
    }
    public static func addToAuthUser(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: .authUser))
    }
    public static func addToSuperUser(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: .superUser))
    }
    public static func addToAdmin(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: .admin))
    }
    public static func getAllRoutes() -> Routes {
        let routes = CSRoutes.routes.map { $0.route }
        return Routes(routes)
    }
    public static func getAllUnrestrictedRoutes() -> Routes {
        let routes = CSRoutes.routes.filter { $0.accessLevel == .guest }.map { $0.route }
        return Routes(routes)
    }
    public static func getAllRestrictedRoutes() -> Routes {
        let routes = CSRoutes.routes.filter { $0.accessLevel != .guest }.map { $0.route }
        return Routes(routes)
    }
    public static func getRoutes(accessLevel: CSAccessLevel) -> Routes {
        let routes = CSRoutes.routes.filter { $0.accessLevel == accessLevel }.map { $0.route }
        return Routes(routes)
    }
}
public struct CSRoute {
    let route: Route
    let accessLevel: CSAccessLevel
}

public enum CSAccessLevel {
    case guest
    case authUser
    case superUser
    case admin
}
