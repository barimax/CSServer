//
//  Extensions.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 6.11.19.
//

import Foundation

extension String {

    init(randomWithLength length: Int) {
        let charactersString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString = charactersString.randomString(length: length)
        self.init(randomString)
    }

    public func randomString(length: Int) -> String {
        let charactersArray : [Character] = Array(self)

        var string = ""
        for _ in 0..<length {
            string.append(charactersArray[getRandomNum() % charactersArray.count])
        }

        return string
    }

    public func generateHash(salt: String) throws -> String {
        let stringWithSalt = salt + self
        
        guard let stringArray = stringWithSalt.digest(.sha256)?.encode(.base64) else {
            throw AuthError.passwordGeneratorError
        }

        guard let stringHash = String(data: Data(bytes: stringArray, count: stringArray.count), encoding: .utf8) else {
            throw AuthError.passwordGeneratorError
        }

        return stringHash
    }

    private func getRandomNum() -> Int {
        #if os(Linux)
            srandom(UInt32(time(nil)))
            return Int(random())
        #else
            return Int(arc4random())
        #endif
    }

}
