//
//  AuthFilter.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 7.11.19.
//
import Foundation
import PerfectHTTP
import PerfectCrypto
import PerfectCRUD
import PerfectMySQL

struct UserCredentials {
    public let email: String
    public let userRole: Int
    public let organization: Organization
}

public struct AuthorizationFilter: HTTPRequestFilter {
    
    public func filter(request: HTTPRequest, response: HTTPResponse, callback: (HTTPRequestFilterResult) -> ()) {
        guard CSServer.configuration!.healthyCheckPath != request.uri else {
            return callback(.continue(request, response))
        }
        guard let routeOptions: (CSAccessLevel, CSSessionType) = CSServer.routes.getRouteOptions(uri: request.uri) else {
            return callback(.halt(request, response))
        }
        var createSession: Bool = true
        var session: CSSession = CSSession()
        let sessionManager: CSSessionManager = CSSessionManager()
        if routeOptions.1 == .cookie {
            if let cookieToken = request.getCookie(name: "\(CSServer.configuration!.domain)Session") {
                session = sessionManager.resume(token: cookieToken)
            }
        }else{
            if var bearer = request.header(.authorization), !bearer.isEmpty, bearer.hasPrefix("Bearer ") {
                bearer.removeFirst("Bearer ".count)
                if let jwt = JWTVerifier(bearer) {
                    do {
                        try jwt.verify(algo: .hs256, key: HMACKey(CSServer.configuration!.secret))
                        try jwt.verifyExpirationDate()
                        if let token = jwt.payload[ClaimsNames.sessionToken.rawValue] as? String {
                            session = sessionManager.resume(token: token)
                        }
                    }catch{
                        print(error)
                    }
                }
            }
        }
        if !session.token.isEmpty {
            if session.isValid(request) {
                request.session = session
                createSession = false
            } else {
                sessionManager.destroy(request, response)
            }
        }
        if createSession {
            request.session = sessionManager.start(request)
        }
        if routeOptions.0 != .guest && request.session?.userId == 0 {
            if routeOptions.1 == .cookie {
                response.setHeader(.wwwAuthenticate, value: "BASIC")
            }else{
                response.setHeader(.wwwAuthenticate, value: "BEARER")
            }
            response.status = .unauthorized
            callback(.halt(request, response))
        }
        callback(.continue(request, response))
//        guard let h = CSServer.routes.getAllRestrictedRoutes().navigator.findHandler(uri: request.uri, webRequest: request) else {
//            return callback(.continue(request, response))
//        }
//        print(h)
        guard var header = request.header(.authorization) else {
            response.completed(status: .custom(code: 403, message: "Not Authorized."))
            return callback(.halt(request, response))
        }
        
        guard header.starts(with: "Bearer ") else {
            response.completed(status: .custom(code: 403, message: "Not Authorized."))
            return callback(.halt(request, response))
        }
        
        do {
            header.removeFirst(7)
            
            guard let jwt = JWTVerifier(header) else {
                response.completed(status: .custom(code: 403, message: "Not Authorized."))
                return callback(.halt(request, response))
            }
            
            try jwt.verify(algo: .hs256, key: HMACKey(CSServer.configuration!.secret))
            try jwt.verifyExpirationDate()

            try self.addUserCredentialsToRequest(request: request, jwt: jwt)
        } catch {
            print("Failed to decode JWT: \(error)")
            response.completed(status: .custom(code: 403, message: "Not Authorized."))
            return callback(.halt(request, response))
        }
        
        callback(.continue(request, response))
    }
    
  

    private func addUserCredentialsToRequest(request: HTTPRequest, jwt: JWTVerifier) throws {
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        if let email = jwt.payload[ClaimsNames.email.rawValue] as? String,
            let role = jwt.payload[ClaimsNames.role.rawValue] as? Int,
            let organizationId = jwt.payload[ClaimsNames.org.rawValue] as? Int,
            let organization = try? db.table(Organization.self).where(\Organization.id == UInt64(organizationId)).first() {
                let userCredentials = UserCredentials(email: email, userRole: role, organization: organization)
            request.add(userCredentials: userCredentials)
        }
    }
    public static func authFilter(data: [String:Any]) throws -> HTTPRequestFilter {
        AuthorizationFilter()
    }
}

