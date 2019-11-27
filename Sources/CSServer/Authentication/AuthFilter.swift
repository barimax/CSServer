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
        guard let h = CSServer.routes.getAllRestrictedRoutes().navigator.findHandler(uri: request.uri, webRequest: request) else {
            return callback(.continue(request, response))
        }
        print(h)
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

