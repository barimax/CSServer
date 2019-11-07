//
//  AuthFilter.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 7.11.19.
//
import Foundation
import PerfectHTTP
import PerfectCrypto

public class AuthorizationFilter: HTTPRequestFilter {
    
    private let secret: String
    private let routesWithAuthorization: Routes
    
    public init(secret: String, routesWithAuthorization: Routes) {
        self.secret = secret
        self.routesWithAuthorization = routesWithAuthorization
    }
    
    public func filter(request: HTTPRequest, response: HTTPResponse, callback: (HTTPRequestFilterResult) -> ()) {
        
        guard let _ = self.routesWithAuthorization.navigator.findHandler(uri: request.uri, webRequest: request) else {
            return callback(.continue(request, response))
        }
        
        guard var header = request.header(.authorization) else {
            response.sendUnauthorizedError()
            return callback(.halt(request, response))
        }
        
        guard header.starts(with: "Bearer ") else {
            response.sendUnauthorizedError()
            return callback(.halt(request, response))
        }
        
        do {
            header.removeFirst(7)
            
            guard let jwt = JWTVerifier(header) else {
                response.sendUnauthorizedError()
                return callback(.halt(request, response))
            }
            
            try jwt.verify(algo: .hs256, key: HMACKey(secret))
            try jwt.verifyExpirationDate()

            self.addUserCredentialsToRequest(request: request, jwt: jwt)
            
        } catch is JWTTokenExpirationDateError {
            print("Token expiration date error.")
            response.sendUnauthorizedError()
            return callback(.halt(request, response))
        } catch {
            print("Failed to decode JWT: \(error)")
            response.sendUnauthorizedError()
            return callback(.halt(request, response))
        }
        
        callback(.continue(request, response))
    }

    private func addUserCredentialsToRequest(request: HTTPRequest, jwt: JWTVerifier) {
        if let name = jwt.payload[ClaimsNames.name.rawValue] as? String {
            let userCredentials = UserCredentials(
                name: name,
                roles: jwt.payload[ClaimsNames.roles.rawValue] as? [String]
            )
            request.add(userCredentials: userCredentials)
        }
    }
}

