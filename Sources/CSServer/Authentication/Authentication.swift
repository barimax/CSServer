//
//  Authentication.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//

import Foundation
import PerfectCrypto

public class Authentication {
    func prepareToken(user: User) throws -> String {

        let payload = [
            ClaimsNames.email.rawValue           : user.email,
            ClaimsNames.role.rawValue          : user.userRole,
            ClaimsNames.issuer.rawValue         : CSServer.configuration!.domain,
            ClaimsNames.issuedAt.rawValue       : Date().timeIntervalSince1970,
            ClaimsNames.expiration.rawValue     : Date().addingTimeInterval(36000).timeIntervalSince1970
        ] as [String : Any]

        guard let jwt = JWTCreator(payload: payload) else {
            throw AuthError.prepareTokenError
        }
        return try jwt.sign(alg: .hs256, key: CSServer.configuration!.secret)
    }
}
public enum ClaimsNames : String {
    case email = "email"
    case role = "role"
    case issuer = "iss"
    case issuedAt = "iat"
    case expiration = "exp"
}
