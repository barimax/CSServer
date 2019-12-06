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
        
        CSRoutes.add(method: .post, uri: "/registration", handler: AuthHandlers.registration, access: .guest, sessionType: .bearer)
        CSRoutes.add(method: .post, uri: "/login", handler: AuthHandlers.login, access: .guest, sessionType: .bearer)
        CSRoutes.add(method: .post, uri: "/resetPassword", handler: AuthHandlers.resetPassword, access: .guest, sessionType: .bearer)
        CSRoutes.add(method: .get, uri: "/emailValidation", handler: AuthHandlers.validateEmail, access: .guest, sessionType: .bearer)
        CSRoutes.add(method: .post, uri: "/resendValidationEmail", handler: AuthHandlers.resendVaidationEmail, access: .guest, sessionType: .bearer)
        CSRoutes.addToSuperUser(method: .post, uri: "/changePassword", handler: AuthHandlers.changePassword)
        CSRoutes.add(method: .get, uri: "/**", handler: AuthHandlers.loginForm, access: .guest, sessionType: .cookie)
    }
}

public struct CSRoutes {
    private static var routes: [CSRoute] = []
    
    public static func add(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: .guest, sessionType: .cookie))
    }
    public static func add(method: HTTPMethod, uri: String, handler: @escaping RequestHandler, access a: CSAccessLevel, sessionType st: CSSessionType) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: a, sessionType: st))
    }
    public static func addToAuthUser(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: .authUser, sessionType: .cookie))
    }
    public static func addToSuperUser(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: .superUser, sessionType: .bearer))
    }
    public static func addToAdmin(method: HTTPMethod, uri: String, handler: @escaping RequestHandler) {
        let route = Route(method: method, uri: uri, handler: handler)
        routes.append(CSRoute(route: route, accessLevel: .admin, sessionType: .bearer))
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
    public static func getRouteOptions(uri: String) -> (CSAccessLevel, CSSessionType)? {
        let rs = self.routes.filter { $0.route.uri == uri }
        if rs.count != 1 { return nil }
        return (rs[0].accessLevel, rs[0].sessionType)
    }
}
public struct CSRoute {
    let route: Route
    let accessLevel: CSAccessLevel
    let sessionType: CSSessionType
}

public enum CSAccessLevel {
    case guest
    case authUser
    case superUser
    case admin
}
public enum CSSessionType {
    case bearer
    case cookie
}
