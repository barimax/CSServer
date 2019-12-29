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
        /// Registration and authentication
        /// Registration API endpoint HTTP method="POST", accepts HTTP header Content-Type="application/json" and json body:
        /// - email: String
        /// - password: String - should be checked in front end
        /// - orgName: String
        /// - orgAddress: String
        /// - orgEIK: String - must be valid Bulgarian commercial id number
        /// - orgMOL: String
        /// - orgDescription: String
        /// Registration API endpoint returns on success HTTP header Content-Type="application/json" and json body:
        /// - type: "json",
        /// - body: Object:
        /// - email: String - the same as in the registration request body
        /// - userId: Number(UInt64) - the database id of the registred user
        /// - isValidated: Bool - indicates if user email is verified
        /// On fail registration API endpoint returns HTTP error code (not ok 200) with description
        CSRoutes.add(method: .post, uri: "/registration", handler: AuthHandlers.registration, access: .guest, sessionType: .bearer)
        
        /// Login API endpoint HTTP method="POST", accepts HTTP headers:
        /// - Content-Type="application/json"
        /// - Authorization="Bearer  """ - empty string after Bearer is a must
        /// - JSON body:
        /// - email: String
        /// - password: String
        /// On success login API enpoint returns HTTP header Content-Type="application/json" and try to set a cookie named [domain]Session containg session ID. Returns JSON body:
        /// - type: "json",
        /// - body: Object:
        /// - email: String - the same as in the registration request body
        /// - isValidated: Bool - indicates if user email is verified
        /// - userId: Number(UInt64) - the database id of the registred user
        /// - token (Optional): String - This property apear only  if user email is verified and contains newly created Bearer token. Must check for existance and  include the token in all request to access.
        /// On fail login API endpoint returns HTTP error code (not ok 200) with description
        CSRoutes.add(method: .post, uri: "/api/v1/login", handler: AuthHandlers.bearerLogin, access: .guest, sessionType: .bearer)
        
        /// Web login URL HTTP method="POST", accepts HTTP header Authorization="Basic  [base64 encoded username and password]"
        /// On success returns html body
        /// On fail web login  returns HTTP error code (not ok 200) with description
        CSRoutes.add(method: .post, uri: "/login", handler: AuthHandlers.login, access: .guest, sessionType: .cookie)
        
        /// Reset password API enpoint HTTP method="POST", accepts HTTP header Content-Type="application/json" and JSON body:
        /// - email: String
        /// Reset password API endpoint returns on success HTTP header Content-Type="application/json" and json body:
        /// - type: "json",
        /// - body: Object:
        /// - email: String - the same as in the registration request body
        /// On fail reset password API endpoint returns HTTP error code (not ok 200) with description
        CSRoutes.add(method: .post, uri: "/resetPassword", handler: AuthHandlers.resetPassword, access: .guest, sessionType: .bearer)
        
        /// Email validation HTTP method="GET" web URL parameter s=[validationString]
        /// Email validation webURL returns on success HTTP header Content-Type="application/json" and json body:
        /// - type: "json",
        /// - body: Object:
        /// - email: String - the same as in the registration request body
        /// - userId: Number(UInt64) - the database id of the registred user
        /// - isValidated: Bool = true
        /// On fail email validation webURL returns HTTP error code (not ok 200) with description
        CSRoutes.add(method: .get, uri: "/emailValidation", handler: AuthHandlers.validateEmail, access: .guest, sessionType: .bearer)
        
        /// Resend validation email API endpoint HTTP method="POST", accepts HTTP header Content-Type="application/json" and json body:
        /// - email: String
        /// Registration API endpoint returns on success HTTP header Content-Type="application/json" and json body:
        /// - type: "bool"
        /// - body: Bool
        /// On fail resend validation email API endpoint returns HTTP error code (not ok 200) with description
        CSRoutes.add(method: .post, uri: "/resendValidationEmail", handler: AuthHandlers.resendVaidationEmail, access: .guest, sessionType: .bearer)
        
        /// Change password API endpoint HTTP method="POST", accepts HTTP headers:
        /// - Content-Type="application/json"
        /// - Authorization="Bearer  [token]" - must be logged to change password
        /// - JSON body:
        /// - oldPassword: String
        /// - newPassword: String
        /// Change password  API endpoint returns on success HTTP header Content-Type="application/json" and json body:
        /// - type: "json",
        /// - body: Object:
        /// - email: String - the same as in the registration request body
        /// - userId: Number(UInt64) - the database id of the registred user
        /// - isValidated: Bool - indicates if user email is verified
        /// On fail change password  API endpoint returns HTTP error code (not ok 200) with description
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
