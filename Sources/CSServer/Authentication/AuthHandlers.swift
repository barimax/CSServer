//
//  AuthHandlers.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//


import PerfectHTTPServer
import PerfectHTTP

class AuthHandlers {
    static public func registration(data: [String:Any]) throws -> RequestHandler {
        return {
            request, response in
        }
    }
    static public func loginForm(data: [String:Any]) throws -> RequestHandler {
        return {
            request, response in
            Authentication().loginForm(request: request, response: response)
        }
    }
}
