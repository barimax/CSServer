//
//  AuthFilter.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 7.11.19.
//
import Foundation
import PerfectHTTP
import PerfectCrypto

struct UserCredentials {
    public let email: String
    public let userRole: Int
}

public class AuthorizationFilter: HTTPRequestFilter {
    
    private let secret: String
    
    public init(secret: String) {
        self.secret = secret
    }
    
    public func filter(request: HTTPRequest, response: HTTPResponse, callback: (HTTPRequestFilterResult) -> ()) {
        if request.uri == "\(CSServer.configuration!.domainURL)/lgoin" ||
            request.uri == "\(CSServer.configuration!.domainURL)/registration" ||
            request.uri == "\(CSServer.configuration!.domainURL)/emailValidation" {
            print("Guest.")
            return callback(.continue(request, response))
        }
        print("Must Auth!")
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
            
            try jwt.verify(algo: .hs256, key: HMACKey(secret))
            try jwt.verifyExpirationDate()

            self.addUserCredentialsToRequest(request: request, jwt: jwt)
            
//        } catch AuthError.jwtError(error: <#T##JWTError#>) {
//            response.sendUnauthorizedError()
//            return callback(.halt(request, response))
        } catch {
            print("Failed to decode JWT: \(error)")
            response.completed(status: .custom(code: 403, message: "Not Authorized."))
            return callback(.halt(request, response))
        }
        
        callback(.continue(request, response))
    }

    private func addUserCredentialsToRequest(request: HTTPRequest, jwt: JWTVerifier) {
        if let email = jwt.payload[ClaimsNames.email.rawValue] as? String,
            let role = jwt.payload[ClaimsNames.role.rawValue] as? Int {
            let userCredentials = UserCredentials(email: email, userRole: role
            )
            request.add(userCredentials: userCredentials)
        }
    }
}

