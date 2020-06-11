//
//  Utility.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 6.11.19.
//

import PerfectSMTP
import PerfectCURL

public class Utility {
    public func sendMail(name: String = "",
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
    private func charToInt(_ char: Character) -> Int? {
        return Int(String([char])) ?? 0
    }
    public func idValidation(str: String) -> Bool {
        var isValid = false
        let strCount = str.count
        
        if strCount == 10 {
            // EGN validation 2, 4, 8, 5, 10, 9, 7, 3, 6,
            guard let s0 = charToInt(str[0]) else {
                return false
            }
            var egnSum = s0 * 2
            if let s1 = charToInt(str[1]), let s2 = charToInt(str[2]), let s3 = charToInt(str[3]), let s4 = charToInt(str[4]), let s5 = charToInt(str[5]), let s6 = charToInt(str[6]), let s7 = charToInt(str[7]), let s8 = charToInt(str[8]) {
                egnSum = egnSum  + (s1 * 4)
                egnSum = egnSum  + (s2 * 8)
                egnSum = egnSum  + (s3 * 5)
                egnSum = egnSum  + (s4 * 10)
                egnSum = egnSum  + (s5 * 9)
                egnSum = egnSum  + (s6 * 7)
                egnSum = egnSum  + (s7 * 3)
                egnSum = egnSum  + (s8 * 6)
            }else{
                return false
            }
            let reminder = egnSum  % 11
            guard let s9 = charToInt(str[9]) else {
                return false
            }
            if(reminder == 0 || reminder == 10){
                if s9 == 0 {
                    isValid = true
                }
            }else if reminder == s9 {
                isValid = true
            }
        }else if strCount == 9 || strCount == 13 {
            // check EIK type
            if strCount == 9 {
                if let s0 = charToInt(str[0]), let s1 = charToInt(str[1]), let s2 = charToInt(str[2]), let s3 = charToInt(str[3]), let s4 = charToInt(str[4]), let s5 = charToInt(str[5]), let s6 = charToInt(str[6]), let s7 = charToInt(str[7]), let s8 = charToInt(str[8])  {
                    var eikSum = s0 * 1
                    eikSum = eikSum + (s1 * 2)
                    eikSum = eikSum + (s2 * 3)
                    eikSum = eikSum + (s3 * 4)
                    eikSum = eikSum + (s4 * 5)
                    eikSum = eikSum + (s5 * 6)
                    eikSum = eikSum + (s6 * 7)
                    eikSum = eikSum + (s7 * 8)
                    var reminder = eikSum % 11;
                    if reminder != 10 {
                        if reminder == s8 {
                            isValid = true
                        }
                    }else{
                        eikSum = s0 * 3;
                        eikSum = eikSum + (s1 * 4);
                        eikSum = eikSum + (s2 * 5);
                        eikSum = eikSum + (s3 * 6);
                        eikSum = eikSum + (s4 * 7);
                        eikSum = eikSum + (s5 * 8);
                        eikSum = eikSum + (s6 * 9);
                        eikSum = eikSum + (s7 * 10);
                        reminder = eikSum % 11;
                        if reminder != 10 {
                            if reminder == s8 {
                                isValid = true
                            }
                        }else{
                            if s8 == 0 {
                                isValid = true
                            }
                        }
                    }
                }
            }else if strCount == 13 {
                var result = false;
                var eikSum = 0
                if let s0 = charToInt(str[0]), let s1 = charToInt(str[1]), let s2 = charToInt(str[2]), let s3 = charToInt(str[3]), let s4 = charToInt(str[4]), let s5 = charToInt(str[5]), let s6 = charToInt(str[6]), let s7 = charToInt(str[7]), let s8 = charToInt(str[8]), let s9 = charToInt(str[9]), let s10 = charToInt(str[10]), let s11 = charToInt(str[11]), let s12 = charToInt(str[12])  {
                    eikSum = s0 * 1;
                    eikSum = eikSum + (s1 * 2);
                    eikSum = eikSum + (s2 * 3);
                    eikSum = eikSum + (s3 * 4);
                    eikSum = eikSum + (s4 * 5);
                    eikSum = eikSum + (s5 * 6);
                    eikSum = eikSum + (s6 * 7);
                    eikSum = eikSum + (s7 * 8);
                    var reminder = eikSum % 11;
                    if reminder != 10 {
                        if reminder == s8 {
                            result = true;
                        }
                    }else{
                        eikSum = s0 * 3;
                        eikSum = eikSum + (s1 * 4);
                        eikSum = eikSum + (s2 * 5);
                        eikSum = eikSum + (s3 * 6);
                        eikSum = eikSum + (s4 * 7);
                        eikSum = eikSum + (s5 * 8);
                        eikSum = eikSum + (s6 * 9);
                        eikSum = eikSum + (s7 * 10);
                        reminder = eikSum % 11;
                        if reminder != 10 {
                            if reminder == s8 {
                                result = true;
                            }
                        }else{
                            if s8 == 0 {
                                result = true;
                            }
                        }
                    }
                    if(result){
                        eikSum = s8 * 2;
                        eikSum = eikSum + (s9 * 7);
                        eikSum = eikSum + (s10 * 3);
                        eikSum = eikSum + (s11 * 5);
                        reminder = eikSum % 11;
                        if reminder != 10 {
                            if reminder == s12 {
                                isValid = true
                            }
                        }else{
                            eikSum = s8 * 4;
                            eikSum = eikSum + (s9 * 9);
                            eikSum = eikSum + (s10 * 5);
                            eikSum = eikSum + (s11 * 7);
                            reminder = eikSum % 11;
                            if reminder != 10 {
                                if reminder == s8 {
                                    isValid = true
                                }
                            }else{
                                if s8 == 0 {
                                    isValid = true
                                }
                            }
                        }
                    }
                }
            }
        }
        return isValid
    }
}
