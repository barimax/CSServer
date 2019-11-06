//
//  AuthHandlers.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//


import PerfectHTTPServer
import PerfectHTTP

class AuthHandlers {
    
    static public func loginForm(data: [String:Any]) throws -> RequestHandler {
        return {
            request, response in
            Authentication().loginForm(request: request, response: response)
        }
    }
    static public func registration(data: [String:Any]) throws -> RequestHandler {
        return {
            request, response in
            do {
                try Authentication().registration(request: request, response: response)
            } catch {
                response.status = .custom(code: 510, message: "\(error)")
                response.completed()
            }
        }
    }
}
