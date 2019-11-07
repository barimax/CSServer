//
//  Utility.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 6.11.19.
//

import PerfectSMTP
import PerfectCURL

public class Utility {
    public static func sendMail(name: String = "",
                                address: String,
                                subject: String,
                                html: String = "",
                                text: String = "",
                                completion: ((Int?, String?, String?) -> Void)? = nil) {
        
        if html.isEmpty && text.isEmpty {
            if let handler = completion {
                handler(nil, nil, nil)
            }
            return
        }
        guard let configuration = CSServer.configuration else {
            if let handler = completion {
                handler(nil, nil, nil)
            }
            return
        }
        let client = SMTPClient(url: configuration.smtpConfiguration.mailserver, username: configuration.smtpConfiguration.mailuser, password: configuration.smtpConfiguration.mailpass)
        
        let email = EMail(client: client)
        email.subject = subject
        
        // set the sender info
        email.from = Recipient(name: configuration.smtpConfiguration.mailfromname, address: configuration.smtpConfiguration.mailfromaddress)
        if !html.isEmpty { email.content = html }
        if !text.isEmpty { email.text = text }
        email.to.append(Recipient(name: name, address: address))
        do {
            
            try email.send { code, header, body in
                /// response info from mail server
                if let handler = completion {
                    print(body)
                    handler(code, header, body)
                }
            }
        
        } catch {
            /// something wrong
            if let handler = completion {
                handler(nil, nil, nil)
            }
        }
    }
}
