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


extension Authentication {
    private func databaseNameGenerator(connection: Database<MySQLDatabaseConfiguration>) throws -> String {
        let dbName: String = String(randomWithLength: 20)
        let r = try connection.table(Organization.self).where(\Organization.dbName == dbName).count()
        if r > 0 {
            return try self.databaseNameGenerator(connection: connection)
        }
        return dbName
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
                database: CSServer.masterDBName,
                host: CSServer.host,
                port: CSServer.port,
                username: CSServer.username,
                password: CSServer.password)
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
                            validationString: String(randomWithLength: 20)
            )
            try db.table(User.self).insert(user)
        }
        
        response.setBody(string: "Check email to complete registration.")
        response.completed()
    }
}
