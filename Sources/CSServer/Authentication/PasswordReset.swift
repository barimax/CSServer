//
//  PasswordReset.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 5.11.19.
//

import Foundation
import PerfectHTTP
import PerfectMySQL
import PerfectCRUD
import PerfectMustache

extension Authentication {
    func passwordResetForm(request: HTTPRequest, response: HTTPResponse) throws -> String {
        let templatePath = "\(CSServer.configuration!.template)/passwordResetForm.mustache"
        guard let csrf = request.session?.data["csrf"] else {
            throw AuthError.invalidRequest
        }
        
        let map: [String:Any] = ["csrf":csrf]
        let context = MustacheEvaluationContext(templatePath: templatePath, map: map)
        let collector = MustacheEvaluationOutputCollector()
        return try context.formulateResponse(withCollector: collector)
    }
    
    func passwordChange(request: HTTPRequest, response: HTTPResponse) throws {
        struct PasswordChangeBody: Decodable {
            let oldPassword: String
            let newPassword: String
        }
        guard let requestBody = request.postBodyString,
            let data = requestBody.data(using: .utf8) else {
            throw AuthError.invalidRequest
        }
        let decoded = try JSONDecoder().decode(PasswordChangeBody.self, from: data)
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        guard let email = request.session?.userCredentials?.email,
            let dbResult = try? db.table(User.self).where(\User.email == email).first(),
            var user: User = dbResult else {
            throw AuthError.withDescription(message: "User not found.")
        }
        let hashedPassword: String = try decoded.oldPassword.generateHash(salt: user.salt)
        if hashedPassword != user.password {
            throw AuthError.invalidEmailPassword
        }
        let newHashedPassword: String = try decoded.newPassword.generateHash(salt: user.salt)
        user.password = newHashedPassword
        try db.table(User.self).where(\User.id == user.id).update(user)
        if user.isLocked {
            let resp: AuthResponse = AuthResponse(userId: user.id, email: user.email, isValidated: !user.isLocked)
            response.sendResponse(body: resp, responseType: .json)
        }
        let resp: AuthResponse = AuthResponse(userId: user.id, email: user.email, isValidated: !user.isLocked)
        response.sendResponse(body: resp, responseType: .json)
    }
    func passwordReset(request: HTTPRequest, response: HTTPResponse) throws {
        struct PasswordResetBody: Decodable {
            let email: String
        }
        guard let requestBody = request.postBodyString,
            let data = requestBody.data(using: .utf8) else {
            throw AuthError.invalidRequest
        }
        let decoded = try JSONDecoder().decode(PasswordResetBody.self, from: data)
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        guard var user: User = try db.table(User.self).where(\User.email == decoded.email).first(),
            let organization = try db.table(Organization.self).where(\Organization.id == user.organizationId).first() else {
            throw AuthError.withDescription(message: "User not found.")
        }
        let newPassword: String = String(randomWithLength: 8)
        user.password = try newPassword.generateHash(salt: user.salt)
        try db.transaction {
            try db.table(User.self).where(\User.id == user.id).update(user)
            Utility().sendMail(
                name: organization.name,
                address: user.email,
                subject: "Password reset",
                html: try self.resetPasswordEmail(newPassword: newPassword),
                text: ""
            )
        }
        response.sendResponse(body: PasswordResetResponse(email: user.email), responseType: .json)
    }
    func resetPasswordEmail(newPassword: String) throws -> String {
        let templatePath = "\(CSServer.configuration!.template)/resetPassword.mustache"
        let map: [String:Any] = [
            "password": newPassword,
            "domainURL": CSServer.configuration!.domainURL,
        ]
        let context = MustacheEvaluationContext(templatePath: templatePath, map: map)
        let collector = MustacheEvaluationOutputCollector()
        let s = try context.formulateResponse(withCollector: collector)
        return s
    }
    private struct PasswordResetResponse: Encodable {
        let email: String
    }
}
