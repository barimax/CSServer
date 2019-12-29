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

struct UserCredentials: Codable {
    public let email: String
    public let userRole: Int
    public let organization: Organization
}

public struct AuthorizationFilter: HTTPRequestFilter {
    
    public func filter(request: HTTPRequest, response: HTTPResponse, callback: (HTTPRequestFilterResult) -> ()) {
        guard CSServer.configuration!.healthyCheckPath != request.uri else {
            return callback(.continue(request, response))
        }
        print("check start")
        let routeOptions = CSServer.routes.getRouteOptions(uri: request.uri) ?? (.guest, .cookie)
        print(routeOptions)
        var createSession: Bool = true
        var session: CSSession = CSSession()
        let sessionManager: CSSessionManager = CSSessionManager()
        if routeOptions.1 == .cookie {
            if let cookieToken = request.getCookie(name: "\(CSServer.configuration!.domain)Session") {
                session = sessionManager.resume(token: cookieToken)
            }
        }else if routeOptions.0 != .guest{
            createSession = false
            do {
                guard var bearer = request.header(.authorization), !bearer.isEmpty, bearer.hasPrefix("Bearer ") else {
                    throw AuthError.invalidRequest
                }
                bearer.removeFirst("Bearer ".count)
                guard let jwt = JWTVerifier(bearer) else {
                    throw AuthError.invalidRequest
                }
                try jwt.verify(algo: .hs256, key: HMACKey(CSServer.configuration!.secret))
                try jwt.verifyExpirationDate()
                guard let token = jwt.payload[ClaimsNames.sessionToken.rawValue] as? String else {
                    throw AuthError.invalidRequest
                }
                session = sessionManager.resume(token: token)
            }catch{
                response.status = .unauthorized
                response.setHeader(.wwwAuthenticate, value: "Bearer")
                callback(.halt(request, response))
            }
        }else{
            createSession = false
        }
        if !session.token.isEmpty {
            if session.isValid(request) {
                print("session is valid")
                request.session = session
                createSession = false
            } else {
                sessionManager.destroy(request, response)
            }
        }
        if createSession {
            print("create session")
            request.session = sessionManager.start(request)
        }
        if routeOptions.0 != .guest && request.session?.userId == 0 {
            if routeOptions.1 == .cookie {
                response.setHeader(.wwwAuthenticate, value: "Basic")
            }else{
                response.setHeader(.wwwAuthenticate, value: "Bearer")
            }
            response.status = .unauthorized
            callback(.halt(request, response))
        }
        callback(.continue(request, response))
    }

    public static func authFilter(data: [String:Any]) throws -> HTTPRequestFilter {
        AuthorizationFilter()
    }
}

struct SessionResponseFilter: HTTPResponseFilter {
    /// Called once before headers are sent to the client.
    func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
        guard let session = response.request.session else {
            return callback(.continue)
        }
        // Zero point in saving an OAuth2 Session because it's not part of the normal session structure!


        CSSessionManager().save(session: session)
        let sessionID = session.token

        // 0.0.6 updates
        var domain = ""
        if !CSServer.configuration!.domain.isEmpty {
            domain = CSServer.configuration!.domain
        }

        if !sessionID.isEmpty {
            response.addCookie(HTTPCookie(
                name: "\(CSServer.configuration!.domain)Session",
                value: "\(sessionID)",
                domain: domain,
                expires: .relativeSeconds(session.idle),
                path: "/",
                secure: false,
                httpOnly: true,
                sameSite: .lax
                )
            )
            // CSRF Set Cookie
//            if SessionConfig.CSRF.checkState {
//                CSRFFilter.setCookie(response)
//            }
        }

        callback(.continue)
        
    }
    /// Called zero or more times for each bit of body data which is sent to the client.
    func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
        callback(.continue)
    }
    public static func sessionFilter(data: [String:Any]) throws -> HTTPResponseFilter {
        SessionResponseFilter()
    }
}

