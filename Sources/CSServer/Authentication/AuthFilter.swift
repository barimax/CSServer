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
        // skip session check if it is healthCheck URI
        guard CSServer.configuration!.healthyCheckPath != request.uri else {
            return callback(.continue(request, response))
        }
        // get route options for session and authenthication
        let routeOptions = CSServer.routes.getRouteOptions(uri: request.uri) ?? (.guest, .cookie)
        var createSession: Bool = true
        var session: CSSession = CSSession()
        let sessionManager: CSSessionManager = CSSessionManager()
        if routeOptions.1 == .cookie {
            // try to resume session if it is cookie route
            if let cookieToken = request.getCookie(name: "\(CSServer.configuration!.domain)Session") {
                session = sessionManager.resume(token: cookieToken)
            }
        }else if routeOptions.0 != .guest{
            // try to Bearer authorization for not guest and not cookie authorization route
            // On success resume the session
            // On fail halt request
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
            // Do not create session for guest route with Bearer authorization
            createSession = false
        }
        // Check if session is resumed
        if !session.token.isEmpty {
            // If valid attached session to the request object or destroy session
            if session.isValid(request) {
                request.session = session
                createSession = false
            } else {
                sessionManager.destroy(request, response)
            }
        }
        // Create new session for cookie route only
        if createSession {
            print("Create new session.")
            request.session = sessionManager.start(request)
        }
        if routeOptions.1 == .cookie || routeOptions.0 != .guest {
            // Now process CSRF
            print("CSRF check start here.")
            if request.session?.state != "new" || request.method == .post {
                if !CSRFFilter.filter(request) {
                    switch CSSessionConfig.CSRF.failAction {
                    case .fail:
                        response.status = .notAcceptable
                        callback(.halt(request, response))
                        return
                    case .log:
                        // LogFile.info("CSRF FAIL")
                        print("CSRF FAIL log here")
                    default:
                        print("CSRF FAIL (console notification only)")
                    }
                }
            }

            CORSheaders.make(request, response)
        }
        // Check if session is NOT authentificated and halt it
        if routeOptions.0 != .guest && request.session?.userId == 0 {
            if routeOptions.1 == .cookie {
                response.setHeader(.wwwAuthenticate, value: "Basic")
            }else{
                response.setHeader(.wwwAuthenticate, value: "Bearer")
            }
            response.status = .unauthorized
            callback(.halt(request, response))
        }
        // Continue with authentificated session or as guest if it is a guest route
        callback(.continue(request, response))
    }
    public static func authFilter(data: [String:Any]) throws -> HTTPRequestFilter {
        return AuthorizationFilter()
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
            if CSSessionConfig.CSRF.checkState {
                CSRFFilter.setCookie(response)
            }
        }

        callback(.continue)
        
    }
    /// Called zero or more times for each bit of body data which is sent to the client.
    func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
        callback(.continue)
    }
    public static func sessionFilter(data: [String:Any]) throws -> HTTPResponseFilter {
        return SessionResponseFilter()
    }
}

