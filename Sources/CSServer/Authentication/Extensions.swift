//
//  Extensions.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 6.11.19.
//

import Foundation
import PerfectCrypto
import PerfectHTTP

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
extension HTTPRequest {
    func add(userCredentials: UserCredentials) {
        self.scratchPad["userCredentials"] = userCredentials
    }

    func getUserCredentials() -> UserCredentials? {
        return self.scratchPad["userCredentials"] as? UserCredentials
    }
}
extension JWTVerifier {
    
    public func verifyExpirationDate() throws {
        if self.payload[ClaimsNames.expiration.rawValue] == nil {
            throw AuthError.jwtError(error: .dateNotExist)
        }
        
        guard let date = extractDate() else {
            throw AuthError.jwtError(error: .incorrectDate)
        }
        
        if date.compare(Date()) == ComparisonResult.orderedAscending {
            throw AuthError.jwtError(error: .expired)
        }
    }
    
    private func extractDate() -> Date? {
        if let timestamp = self.payload[ClaimsNames.expiration.rawValue] as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        if let timestamp = self.payload[ClaimsNames.expiration.rawValue] as? Int {
            return Date(timeIntervalSince1970: Double(timestamp))
        }
        
        if let timestampString = self.payload[ClaimsNames.expiration.rawValue] as? String, let timestamp = Double(timestampString) {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        return nil
    }
}
