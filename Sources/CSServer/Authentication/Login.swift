//
//  Login.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 5.11.19.
//

import Foundation
import PerfectHTTP

extension Authentication {
    func loginForm(request: HTTPRequest, response: HTTPResponse) {
        let loginForm: String = "<h1>Login form</h1>"
        response.setBody(string: loginForm)
        response.completed()
    }
}
