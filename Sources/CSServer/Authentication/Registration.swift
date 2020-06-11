//
//  Registration.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//

import Foundation
import PerfectHTTP
import PerfectCRUD
import PerfectMySQL
import PerfectCrypto
import CSCoreView
import PerfectMustache


extension Authentication {
    private func databaseNameGenerator(connection: Database<MySQLDatabaseConfiguration>) throws -> String {
        let dbName: String = String(randomWithLength: 20)
        let r = try connection.table(Organization.self).where(\Organization.dbName == dbName).count()
        if r > 0 {
            return try self.databaseNameGenerator(connection: connection)
        }
        return dbName
    }
    
    
    func registrationForm(request: HTTPRequest, response: HTTPResponse) throws -> String {
        let templatePath = "\(CSServer.configuration!.template)/registrationForm.mustache"
        guard let csrf = request.session?.data["csrf"] else {
            throw AuthError.invalidRequest
        }
        
        let map: [String:Any] = ["csrf":csrf]
        let context = MustacheEvaluationContext(templatePath: templatePath, map: map)
        let collector = MustacheEvaluationOutputCollector()
        return try context.formulateResponse(withCollector: collector)
    }
    private func validationResult(request: HTTPRequest, response: HTTPResponse) throws -> String {
        let templatePath = "\(CSServer.configuration!.template)/validationResult.mustache"
        let map: [String:Any] = [:]
        let context = MustacheEvaluationContext(templatePath: templatePath, map: map)
        let collector = MustacheEvaluationOutputCollector()
        return try context.formulateResponse(withCollector: collector)
    }
    
    func registration(request: HTTPRequest, response: HTTPResponse) throws {
        struct RegistrationBody: Decodable {
            let email: String
            let password: String
            let orgName: String
            let orgAddress: String
            let orgEIK: String
            let orgMOL: String
            let orgDescription: String
        }
        let utility = Utility()
        guard let requestBody = request.postBodyString,
            let data = requestBody.data(using: .utf8) else {
            throw AuthError.invalidRequest
        }
        let decoded = try JSONDecoder().decode(RegistrationBody.self, from: data)
        if decoded.email == "" || decoded.password == "" || decoded.orgName == "" || decoded.orgAddress == "" || decoded.orgEIK == "" || decoded.orgMOL == "" {
            throw AuthError.invalidRequest
        }
        if !utility.idValidation(str: decoded.orgEIK) {
            throw AuthError.withDescription(message: "Not valid company idetification number.")
        }
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        let dbName: String = try self.databaseNameGenerator(connection: db)
        let organization = Organization(id: 0,
                                        name: decoded.orgName,
                                        adddress: decoded.orgAddress,
                                        eik: decoded.orgEIK,
                                        mol: decoded.orgMOL,
                                        description: decoded.orgDescription,
                                        dbName: dbName
        )
        
        try db.transaction {
            if var existingUser = try db.table(User.self).where(\User.email == decoded.email).first()  {
                if existingUser.isLocked {
                    existingUser.timestamp = Date()
                    try db.table(User.self).where(\User.email == decoded.email).update(existingUser)
                    let resp: AuthResponse = AuthResponse(userId: existingUser.id, email: existingUser.email, isValidated: !existingUser.isLocked)
                    response.sendResponse(body: resp, responseType: .json)
                }else{
                    throw AuthError.userExist
                }
            }
            guard try db.table(Organization.self).where(\Organization.eik == decoded.orgEIK).count() == 0 else {
                throw AuthError.organizationExists
            }
            try db.sql("CREATE DATABASE `\(dbName)` CHARACTER SET utf8 COLLATE utf8_general_ci")
            try CSRegister.setup(withDatabase: dbName, host: CSServer.configuration!.host, username: CSServer.configuration!.username, password: CSServer.configuration!.password)
            guard let newOrgId: UInt64 = try db.table(Organization.self).insert(organization).lastInsertId() else {
                throw AuthError.passwordGeneratorError
            }
            let salt: String = String(randomWithLength: 14)
            let hashedPassword: String = try decoded.password.generateHash(salt: salt)
            let user = User(id: 0,
                            organizationId: newOrgId,
                            name: "",
                            email: decoded.email,
                            password: hashedPassword,
                            phone: "",
                            isLocked: true,
                            userRole: 3,
                            salt: salt,
                            validationString: String(randomWithLength: 20),
                            timestamp: Date()
            )
            try db.table(User.self).insert(user)
        }
        let user = try db.table(User.self).where(\User.email == decoded.email).first()!
        utility.sendMail(
            name: organization.name,
            address: user.email,
            subject: "Validate email",
            html: try self.conformationEmail(validationString: user.validationString),
            text: ""
        )
        let resp: AuthResponse = AuthResponse(userId: user.id, email: user.email, isValidated: !user.isLocked)
        response.sendResponse(body: resp, responseType: .json)
    }
    
    func validateEmail(request: HTTPRequest, response: HTTPResponse) throws {
        guard let validationString = request.param(name: "s") else {
            throw AuthError.invalidRequest
        }
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        
        guard let yesterday = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date()),
            var user: User = try db.table(User.self).where(\User.validationString == validationString && \User.timestamp! > yesterday).first() else {
            try db.transaction {
                let query = db.table(User.self).where(\User.validationString == validationString)
                if let user = try query.first(), user.isLocked {
                    try db.table(Organization.self).where(\Organization.id == user.organizationId).delete()
                    try query.delete()
                }
            }
            
            throw AuthError.notValidatedEmail
        }
        user.isLocked = false
        if user.password.isEmpty,
            let organization = try db.table(Organization.self).where(\Organization.id == user.organizationId).first(){
            let newPassword: String = String(randomWithLength: 8)
            user.password = try newPassword.generateHash(salt: user.salt)
            Utility().sendMail(
                name: organization.name,
                address: user.email,
                subject: "New password",
                html: try self.resetPasswordEmail(newPassword: newPassword),
                text: ""
            )
        }
        try db.table(User.self).where(\User.id == user.id).update(user)
        try response.setBody(string: self.validationResult(request: request, response: response))
        response.completed()
    }
    func resendVaidationEmail(request: HTTPRequest, response: HTTPResponse) throws {
        struct ResendEmail: Codable {
            let email: String
        }
        guard let requestBody = request.postBodyString,
            let data = requestBody.data(using: .utf8) else {
            throw AuthError.invalidRequest
        }
        let decoded = try JSONDecoder().decode(ResendEmail.self, from: data)
        let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
            MySQLDatabaseConfiguration(
                database: CSServer.configuration!.masterDBName,
                host: CSServer.configuration!.host,
                port: CSServer.configuration!.port,
                username: CSServer.configuration!.username,
                password: CSServer.configuration!.password)
        )
        guard let user: User = try db.table(User.self).where(\User.email == decoded.email && \User.isLocked == true).first(),
            let organization: Organization = try db.table(Organization.self).where(\Organization.id == user.organizationId).first() else {
            throw AuthError.invalidEmailPassword
        }
        print(user.email)
        Utility().sendMail(
            name: organization.name,
            address: user.email,
            subject: "Validate email",
            html: try self.conformationEmail(validationString: user.validationString),
            text: ""
        )
        response.sendResponse(body: true, responseType: .bool)
    }
}
