//
//  AuthHandlers.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//


import PerfectHTTPServer
import PerfectHTTP

class AuthHandlers {
    static func loginForm(request: HTTPRequest, _ response: HTTPResponse) {
        Authentication().loginForm(request: request, response: response)
    }
    static func registration(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            try Authentication().registration(request: request, response: response)
        } catch {
            response.status = .custom(code: 510, message: "\(error)")
            response.completed()
        }
    }
    static func validateEmail(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            try Authentication().validateEmail(request: request, response: response)
        } catch {
            response.status = .custom(code: 510, message: "\(error)")
            response.completed()
        }
    }
    static func resetPassword(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            try Authentication().passwordReset(request: request, response: response)
        } catch {
            response.status = .custom(code: 510, message: "\(error)")
            response.completed()
        }
    }
    static func changePassword(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            try Authentication().passwordChange(request: request, response: response)
        } catch {
            response.status = .custom(code: 510, message: "\(error)")
            response.completed()
        }
    }
    static func resendVaidationEmail(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            try Authentication().resendVaidationEmail(request: request, response: response)
        } catch {
            response.status = .custom(code: 510, message: "\(error)")
            response.completed()
        }
    }
    static func login(request: HTTPRequest, _ response: HTTPResponse)  {
        do {
            try Authentication().login(request: request, response: response)
        } catch {
            response.status = .custom(code: 403, message: "\(error)")
            response.completed()
        }
    }
}
