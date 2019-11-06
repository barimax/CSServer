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
        let loginForm: String = #"<html><h1>Login form</h1></html>"#
        response.setBody(string: loginForm)
        response.completed()
    }
}

