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
        let loginForm: String = #"<html><h1>Login form</h1></html>"#
        response.setBody(string: loginForm)
        response.completed()
    }
    func login(request: HTTPRequest, response: HTTPResponse) throws {
        struct LoginBody: Decodable {
            let email: String
            let password: String
        }
        struct TokenBody: Codable {
            let token: String
        }
        guard let requestBody = request.postBodyString,
            let data = requestBody.data(using: .utf8) else {
            throw AuthError.invalidRequest
        }
        let decoded = try JSONDecoder().decode(LoginBody.self, from: data)
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        guard let user: User = try? db.table(User.self).where(\User.email == decoded.email).first() else {
            throw AuthError.withDescription(message: "User not found.")
        }
        let hashedPassword: String = try decoded.password.generateHash(salt: user.salt)
        if hashedPassword != user.password || user.isLocked {
            throw AuthError.invalidEmailPassword
        }
        let token = try TokenBody(token: self.prepareToken(user: user))
        try response.setBody(json: token)
        response.completed()
    }
}

