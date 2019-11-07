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
import SwiftMoment
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
    private func conformationEmail(validationString: String) throws -> String {
        let templatePath = "\(CSServer.configuration!.template)/email.mustache"
        let map: [String:Any] = [
            "validationString": validationString,
            "domainURL": CSServer.configuration!.domainURL
        ]
        let context = MustacheEvaluationContext(templatePath: templatePath, map: map)
        let collector = MustacheEvaluationOutputCollector()
        let s = try context.formulateResponse(withCollector: collector)
        print(s)
        
        return s
//        return """
//        <html>
//            <head>
//                <title>Email from CSServer</title>
//                <style>
//                    #confirm-btn {
//                        background-color: pink;
//                    }
//                </style>
//            </head>
//            <body>
//                <h3>Confirm</h3>
//        <a href="\(CSServer.configuration!.domainURL)/emailValidation?s=\(validationString)" id="confirm-btn">Click to confirm</div>
//            </body>
//        </html>
//        """
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
        guard let requestBody = request.postBodyString,
            let data = requestBody.data(using: .utf8) else {
            throw AuthError.invalidRequest
        }
        let decoded = try JSONDecoder().decode(RegistrationBody.self, from: data)
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
        try db.sql("SET time_zone = '+2:00'")
        try db.transaction {
            guard try db.table(User.self).where(\User.email == decoded.email).count() == 0 else {
                throw AuthError.userExist
            }
            guard try db.table(Organization.self).where(\Organization.eik == decoded.orgEIK).count() == 0 else {
                throw AuthError.organizationExists
            }
            guard let newOrgId: UInt64 = try db.table(Organization.self).insert(organization).lastInsertId() else {
                throw AuthError.passwordGeneratorError
            }
            let salt: String = String(randomWithLength: 14)
            let hashedPassword: String = try decoded.password.generateHash(salt: salt)
            let user = User(id: 0,
                            organizationId: newOrgId,
                            name: "No name",
                            email: decoded.email,
                            password: hashedPassword,
                            phone: "",
                            isLocked: true,
                            userRole: 3,
                            salt: salt,
                            validationString: String(randomWithLength: 20),
                            timestamp: moment(TimeZone(identifier: "Europe/Sofia")!, locale: Locale(identifier: "bg_BG")).date
            )
            try db.table(User.self).insert(user)
        }
        let user = try db.table(User.self).where(\User.email == decoded.email).first()!
        Utility.sendMail(
            name: "Barimax ood",
            address: user.email,
            subject: "Validate email",
            html: try self.conformationEmail(validationString: user.validationString),
            text: ""
        )
        try response.setBody(json: user)
        response.completed()
    }
}
