//
//  Configuration.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 6.11.19.
//

import Foundation
import PerfectSMTP

public struct Configuration {
    public var masterDBName: String
    public var host: String
    public var username: String
    public var password: String
    public var port: Int = 3306
    
    public var smtpConfiguration: SMTPConfig
    
    
}
public struct SMTPConfig {
    public var mailserver: String
    public var mailuser: String
    public var mailpass: String
    
    public var mailfromname: String
    public var mailfromaddress: String
}
