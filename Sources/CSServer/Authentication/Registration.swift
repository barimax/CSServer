//
//  Registration.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//

import Foundation
import PerfectHTTP
import PerfectCRUD
import PerfectCrypto
import CSCoreView

extension Authentication {
    func registration(request: HTTPRequest, response: HTTPResponse) throws {
        guard let requestBody = request.postBodyString,
            let data = requestBody.data(using: .utf8),
            var user = try? JSONDecoder().decode(User.self, from: data) else {
            throw AuthError.invalidRequest
        }
        user.salt = String(randomWithLength: 14)
        user.password = try user.password.generateHash(salt: user.salt)
        user.validationString = String(randomWithLength: 14)
        let entity = try CSEntity(withType: User.self, withDatabase: CSServer.masterDBName)
        let savedUser = try entity.save(entity: user) as! User
    }
}
