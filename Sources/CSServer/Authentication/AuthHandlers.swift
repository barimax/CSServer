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
        do {
            let loginForm: String = try Authentication().loginForm(request: request, response: response)
            response.setBody(string: loginForm)
        } catch {
            response.status = .custom(code: 503, message: "\(error)")
        }
        response.completed()
    }
    static func registrationForm(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            let registrationForm: String = try Authentication().registrationForm(request: request, response: response)
            response.setBody(string: registrationForm)
        } catch {
            response.status = .custom(code: 503, message: "\(error)")
        }
        response.completed()
    }
    static func passwordResetForm(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            let passwordResetForm: String = try Authentication().passwordResetForm(request: request, response: response)
            response.setBody(string: passwordResetForm)
        } catch {
            response.status = .custom(code: 503, message: "\(error)")
        }
        response.completed()
    }
    static func registration(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            try Authentication().registration(request: request, response: response)
        } catch {
            response.status = .custom(code: 401, message: "\(error)")
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
    static func bearerLogin(request: HTTPRequest, _ response: HTTPResponse)  {
        do {
            try Authentication().bearerLogin(request: request, response: response)
        } catch {
            response.status = .custom(code: 403, message: "\(error)")
            response.completed()
        }
    }
    static func logout(request: HTTPRequest, _ response: HTTPResponse)  {
        do {
            let sessionManager = try CSSessionManager()
            sessionManager.destroy(request, response)
            response.setHeader(.location, value: "../")
            response.status = .movedPermanently
            response.completed()
        } catch {
            response.status = .custom(code: 403, message: "\(error)")
            response.completed()
        }
    }
}
