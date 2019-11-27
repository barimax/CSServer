//
//  Authentication.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//

import Foundation
import PerfectCrypto
import PerfectMustache

public class Authentication {
    func prepareToken(user: User) throws -> String {

        let payload = [
            ClaimsNames.email.rawValue          : user.email,
            ClaimsNames.role.rawValue           : user.userRole,
            ClaimsNames.issuer.rawValue         : CSServer.configuration!.domain,
            ClaimsNames.issuedAt.rawValue       : Date().timeIntervalSince1970,
            ClaimsNames.expiration.rawValue     : Date().addingTimeInterval(36000).timeIntervalSince1970,
            ClaimsNames.org.rawValue            : user.organizationId
        ] as [String : Any]

        guard let jwt = JWTCreator(payload: payload) else {
            throw AuthError.prepareTokenError
        }
        return try jwt.sign(alg: .hs256, key: CSServer.configuration!.secret)
    }
    struct AuthResponse: Encodable {
        let userId: UInt64
        let email: String
        let isValidated: Bool
        let token: String?
        
        init(userId u: UInt64, email e: String, isValidated i: Bool, token t: String? = nil){
            self.userId = u
            self.email = e
            self.isValidated = i
            self.token = t
        }
    }
    func conformationEmail(validationString: String) throws -> String {
        let templatePath = "\(CSServer.configuration!.template)/email.mustache"
        let map: [String:Any] = [
            "validationString": validationString,
            "domainURL": CSServer.configuration!.domainURL
        ]
        let context = MustacheEvaluationContext(templatePath: templatePath, map: map)
        let collector = MustacheEvaluationOutputCollector()
        let s = try context.formulateResponse(withCollector: collector)
        return s
    }
    
}
public enum ClaimsNames : String {
    case email = "email"
    case role = "role"
    case issuer = "iss"
    case issuedAt = "iat"
    case expiration = "exp"
    case org = "org"
}
