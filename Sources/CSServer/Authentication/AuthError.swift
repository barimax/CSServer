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
}
