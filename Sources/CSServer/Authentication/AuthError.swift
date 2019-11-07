//
//  AuthError.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 6.11.19.
//

import Foundation

enum AuthError: Error {
    case invalidRequest
    case invalidEmailPassword
    case withDescription(message: String)
    case passwordGeneratorError
    case userExist
    case organizationExists
    case prepareTokenError
    case jwtError(error: JWTError)
}

enum JWTError: Error {
    case expired
    case incorrectDate
    case dateNotExist
}
