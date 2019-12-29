//
//  Login.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 5.11.19.
//

import Foundation
import PerfectHTTP
import PerfectCRUD
import PerfectMySQL
import PerfectCrypto

extension Authentication {
    func loginForm(request: HTTPRequest, response: HTTPResponse) {
        var userEmail: String = ""
        var database: String = ""
        if let userCredentials = request.session?.userCredentials {
            userEmail = userCredentials.email
            database = userCredentials.organization.dbName
        }
        
        let loginForm: String = #"<html><h1>Login form</h1><p>\#(userEmail), db: \#(database)</p></html>"#
        response.setBody(string: loginForm)
        response.completed()
    }
    func bearerLogin(request: HTTPRequest, response: HTTPResponse) throws {
        guard let bearer = request.header(.authorization), !bearer.isEmpty, bearer.hasPrefix("Bearer ") else {
            throw AuthError.invalidRequest
        }
        struct LoginBody: Decodable {
            let email: String
            let password: String
        }
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        guard let requestBody = request.postBodyString,
            let data = requestBody.data(using: .utf8) else {
            throw AuthError.invalidRequest
        }
        let decoded = try JSONDecoder().decode(LoginBody.self, from: data)
        var user = try self.getAuthUser(email: decoded.email, password: decoded.password)
        if user.isLocked {
            user.timestamp = Date()
            try db.table(User.self).where(\User.id == user.id).update(user)
            let resp: AuthResponse = AuthResponse(userId: user.id, email: user.email, isValidated: !user.isLocked)
            response.sendResponse(body: resp, responseType: .json)
        }
        let sessionManager: CSSessionManager = CSSessionManager()
        sessionManager.cleanByUser(userId: user.id)
        var session: CSSession = sessionManager.start(request)
        guard let organization: Organization = try? db.table(Organization.self).where(\Organization.id == user.organizationId).first() else {
            throw AuthError.withDescription(message: "No organization.")
        }
        let userCredentials: UserCredentials = UserCredentials(
            email: user.email,
            userRole: user.userRole,
            organization: organization
        )
        session.userId = user.id
        session.userCredentials = userCredentials
        request.session = session
        let resp: AuthResponse = try AuthResponse(userId: user.id, email: user.email, isValidated: !user.isLocked, token: self.prepareToken(user: user, token: session.token))
        response.sendResponse(body: resp, responseType: .json)
    }
    func login(request: HTTPRequest, response: HTTPResponse) throws {
        guard var basic = request.header(.authorization), !basic.isEmpty, basic.hasPrefix("Basic ") else {
            response.setHeader(.wwwAuthenticate, value: "Basic")
            throw AuthError.invalidRequest
        }
        basic.removeFirst("Basic ".count)
        guard let decodeData: Data = Data(base64Encoded: basic),
            let decodedString = String(data: decodeData, encoding: .utf8) else {
            response.setHeader(.wwwAuthenticate, value: "Basic")
            throw AuthError.invalidRequest
        }
        let credentials: [String] = decodedString.components(separatedBy: ":")
        guard credentials.count == 2 else {
            response.setHeader(.wwwAuthenticate, value: "Basic")
            throw AuthError.invalidRequest
        }
        let email: String = credentials[0]
        let password: String = credentials[1]
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        var user = try self.getAuthUser(email: email, password: password)
        if user.isLocked {
            user.timestamp = Date()
            try db.table(User.self).where(\User.id == user.id).update(user)
            response.completed(status: .custom(code: 403, message: "Not validated"))
        }
        request.session?.userId = user.id
        response.status = .found
        response.setHeader(.location, value: "/")
        response.completed()
    }
    private func getAuthUser(email: String, password: String) throws -> User {
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        guard let user: User = try? db.table(User.self).where(\User.email == email).first() else {
            throw AuthError.withDescription(message: "User not found.")
        }
        let hashedPassword: String = try password.generateHash(salt: user.salt)
        if hashedPassword != user.password {
            throw AuthError.invalidEmailPassword
        }
        return user
    }
}

