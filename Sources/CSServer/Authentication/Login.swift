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

extension Authentication {
    func loginForm(request: HTTPRequest, response: HTTPResponse) {
        var userEmail: String = ""
        var database: String = ""
        if let userRole = request.getUserCredentials() {
            userEmail = userRole.email
            database = userRole.organization.dbName
        }
        
        let loginForm: String = #"<html><h1>Login form</h1><p>\#(userEmail), db: \#(database)</p></html>"#
        response.setBody(string: loginForm)
        response.completed()
    }
    func login(request: HTTPRequest, response: HTTPResponse) throws {
        struct LoginBody: Decodable {
            let email: String
            let password: String
            let redirectURL: String? = nil
        }
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        if let contentType = request.header(.contentType),
            contentType == "application/x-www-form-urlencoded",
            let email = request.param(name: "email"),
            let password = request.param(name: "password") {
            var user = try self.getAuthUser(email: email, password: password)
            if user.isLocked {
                user.timestamp = Date()
                try db.table(User.self).where(\User.id == user.id).update(user)
                response.completed(status: .custom(code: 403, message: "Not validated"))
            }
        }else{
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
            let resp: AuthResponse = try AuthResponse(userId: user.id, email: user.email, isValidated: !user.isLocked, token: self.prepareToken(user: user, token: "demoToken"))
            response.sendResponse(body: resp, responseType: .json)
        }
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

