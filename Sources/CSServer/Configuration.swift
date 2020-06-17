//
//  Configuration.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 6.11.19.
//

import Foundation
import PerfectSMTP

public struct Configuration {
    public static var production: Bool = true
    public var masterDBName: String
    public var host: String
    public var username: String
    public var password: String
    public var port: Int = 3306
    public var domain: String
    public var domainURL: String
    public var webroot: String = "./webroot"
    public var template: String = "./template"
    public var secret: String
    public var healthyCheckPath: String = "/healthCheck"
    public var activeLog: Bool = true
    
    public var smtpConfiguration: SMTPConfig
    
    public init(masterDBName m: String,
                host h: String,
                username u: String,
                password p: String,
                smtpConfiguration sc: SMTPConfig,
                domain d: String,
                domainURL durl: String,
                secret s: String
    ){
        self.masterDBName = m
        self.host = h
        self.password = p
        self.username = u
        self.smtpConfiguration = sc
        self.domain = Configuration.production ? d : "localhost"
        self.domainURL = Configuration.production ? durl : "http://localhost"
        self.secret = s
    }
    
}
public struct SMTPConfig {
    public let mailserver: String
    public let mailuser: String
    public let mailpass: String
    public let mailfromname: String
    public let mailfromaddress: String
    
    public init(mailserver ms: String,
                mailuser mu: String,
                mailpass mp: String,
                mailfromname mfn: String,
                mailfromaddress mfa: String){
        self.mailserver = ms
        self.mailuser = mu
        self.mailpass = mp
        self.mailfromname = mfn
        self.mailfromaddress = mfa
    }
}
