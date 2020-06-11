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
import PerfectMustache

extension Authentication {
    func loginForm(request: HTTPRequest, response: HTTPResponse) throws -> String {
        let templatePath = "\(CSServer.configuration!.template)/loginForm.mustache"
        guard let csrf = request.session?.data["csrf"] else {
            throw AuthError.invalidRequest
        }
        if let userId = request.session?.userId, userId > 0 && request.session?.userCredentials?.userRole == 3 {
            CSMainHandlers.staticWebrootFile(request: request, response)
        }
        let map: [String:Any] = ["csrf":csrf]
        let context = MustacheEvaluationContext(templatePath: templatePath, map: map)
        let collector = MustacheEvaluationOutputCollector()
        return try context.formulateResponse(withCollector: collector)
    }
    func bearerLogin(request: HTTPRequest, response: HTTPResponse) throws {
        guard let bearer = request.header(.authorization), !bearer.isEmpty, bearer.hasPrefix("Bearer") else {
            print("Headers error.")
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
            response.status = .custom(code: 499, message: "notValidatedEmail")
            response.completed()
        }
        let sessionManager: CSSessionManager = try CSSessionManager()
        try sessionManager.cleanByUser(userId: user.id)
        var session: CSSession = try sessionManager.start(request)
        guard let organization: Organization = try db.table(Organization.self).where(\Organization.id == user.organizationId).first() else {
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
        let sessionManager: CSSessionManager = try CSSessionManager()
        try sessionManager.cleanByUser(userId: user.id)
        if user.isLocked {
            user.timestamp = Date()
            try db.table(User.self).where(\User.id == user.id).update(user)
            response.completed(status: .custom(code: 499, message: "Not validated email."))
        }
        guard let organization: Organization = try db.table(Organization.self).where(\Organization.id == user.organizationId).first() else {
            throw AuthError.withDescription(message: "No organization.")
        }
        let userCredentials: UserCredentials = UserCredentials(
            email: user.email,
            userRole: user.userRole,
            organization: organization
        )
        request.session?.userId = user.id
        request.session?.userCredentials = userCredentials
        response.status = .ok
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
        guard let user: User = try db.table(User.self).where(\User.email == email).first() else {
            throw AuthError.withDescription(message: "User not found.")
        }
        let hashedPassword: String = try password.generateHash(salt: user.salt)
        if hashedPassword != user.password {
            throw AuthError.invalidEmailPassword
        }
        return user
    }
}

