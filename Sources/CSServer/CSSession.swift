//
//  CSSession.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 6.12.19.
//

import Foundation
import PerfectHTTP
import PerfectCRUD
import PerfectMySQL

public struct CSSessionConfiguration {
    static var ipAddressLock: Bool = true
    static var userAgentLock: Bool = true
}

public struct CSSession: Codable, TableNameProvider {
    public static let tableName: String = "sessions"
    
    var token: String = ""
    var userId: UInt64 = 0
    var data: [String:String] = [:]
    var userCredentials: UserCredentials?
    var userAgent: String = ""
    var ipAddress: String = ""
    var created: Int = 0
    var updated: Int = 0
    var idle: Int = 86400
    
    /// Compares the timestamps and idle to determine if session has expired
    public func isValid(_ request:HTTPRequest) -> Bool {
        if (updated + idle) > getNow() {
            if CSSessionConfiguration.ipAddressLock {
                // set forwarded-for (comes from well-behaving load balancers)
                let ff = request.header(.xForwardedFor) ?? ""
                if !ff.isEmpty && ff != self.ipAddress {
                    // if ff is not empty, and it doesn't match ipaddress
                    return false

                } else if ff.isEmpty && request.remoteAddress.host != self.ipAddress {
                    // not an x-forwarded-for, and the ip adress is not correct
                    return false
                }
            }
            if CSSessionConfiguration.userAgentLock && request.header(.userAgent) != self.userAgent {
                return false
            }
            return true
        }
        return false
    }
    private func getNow() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
    public mutating func touch() {
        updated = getNow()
    }
    public mutating func setCSRF(){
        let t = data["csrf"] ?? ""
        if t.isEmpty { data["csrf"] = UUID().uuidString }
    }
    func toJSON() -> String {
        var res: String = "{}"
        do {
            if let encoded = try String(data: JSONEncoder().encode(self.data), encoding: .utf8) {
                res = encoded
            }
        }catch{
            print(error)
        }
        return res
    }
    func encodedUserCredentials() -> String {
        var res: String = "null"
        do {
            if let encoded = try String(data: JSONEncoder().encode(self.userCredentials), encoding: .utf8) {
                res = encoded
            }
        }catch{
            print(error)
        }
        return res
    }
}

public struct CSSessionManager {
    func connect() -> MySQL {
        let server = MySQL()
        let _ = server.connect(
            host: CSServer.configuration!.host,
            user: CSServer.configuration!.username,
            password: CSServer.configuration!.password,
            db: CSServer.configuration!.masterDBName,
            port: UInt32(CSServer.configuration!.port)
        )
        return server
    }
    public func setup(){
        let stmt = "CREATE TABLE IF NOT EXISTS `\(CSSession.tableName)` (`token` varchar(255) NOT NULL, `userId` bigint unsigned not null default 0, `created` int NOT NULL DEFAULT 0, `updated` int NOT NULL DEFAULT 0, `idle` int NOT NULL DEFAULT 0, `data` text, `ipAddress` varchar(255), `userAgent` text, `userCredentials` text, PRIMARY KEY (`token`));"
        exec(stmt, params: [])
    }

    func exec(_ statement: String, params: [Any]) {
        let server = connect()
        let lastStatement = MySQLStmt(server)
        let _ = lastStatement.prepare(statement: statement)
        for p in params {
            lastStatement.bindParam("\(p)")
        }
        _ = lastStatement.execute()
        let _ = lastStatement.results()
    }
    
    func clean() {
        let stmt = "DELETE FROM \(CSSession.tableName) WHERE updated + idle < ?"
        exec(stmt, params: [Int(Date().timeIntervalSince1970)])
    }
    func cleanByUser(userId: UInt64) {
        let stmt = "DELETE FROM \(CSSession.tableName) WHERE userId = ?"
        exec(stmt, params: [userId])
    }
    public func save(session: CSSession) {
        var s = session
        s.touch()
        let stmt = "UPDATE \(CSSession.tableName) SET userid = ?, updated = ?, idle = ?, data = ?, userCredentials = ? WHERE token = ?"
        exec(stmt, params: [
            s.userId,
            s.updated,
            s.idle,
            s.toJSON(),
            s.encodedUserCredentials(),
            s.token
        ])
    }

    public func start(_ request: HTTPRequest) -> CSSession {
        var session = CSSession(token: UUID().uuidString)
        session.ipAddress = request.remoteAddress.host
        session.userAgent = request.header(.userAgent) ?? "unknown"
        session.setCSRF()
        // perform INSERT
        let stmt = "INSERT INTO \(CSSession.tableName) (token, userid, created, updated, idle, data, ipaddress, useragent, userCredentials) VALUES(?,?,?,?,?,?,?,?,?)"
        exec(stmt, params: [
            session.token,
            session.userId,
            session.created,
            session.updated,
            session.idle,
            session.toJSON(),
            session.ipAddress,
            session.userAgent,
            session.encodedUserCredentials()
            ])
        return session
    }

    /// Deletes the session for a session identifier.
    public func destroy(_ request: HTTPRequest, _ response: HTTPResponse) {
        let stmt = "DELETE FROM \(CSSession.tableName) WHERE token = ?"
        if let t = request.session?.token {
            exec(stmt, params: [t])
        }
        // Reset cookie to make absolutely sure it does not get recreated in some circumstances.
        var domain = ""
        if !CSServer.configuration!.domain.isEmpty {
            domain = CSServer.configuration!.domain
        }
        response.addCookie(HTTPCookie(
            name: "\(domain)Session",
            value: "",
            domain: domain,
            expires: .relativeSeconds(86400),
            path: "/",
            secure: false,
            httpOnly: true,
            sameSite: .lax
            )
        )
    }

    public func resume(token: String) -> CSSession {
        var session = CSSession(token: token)
        let server = connect()
        let params = [token]
        let lastStatement = MySQLStmt(server)
        let _ = lastStatement.prepare(statement: "SELECT token,userid,created, updated, idle, data, ipaddress, useragent, userCredentials FROM \(CSSession.tableName) WHERE token = ?")
        for p in params {
            lastStatement.bindParam("\(p)")
        }
        _ = lastStatement.execute()
        let result = lastStatement.results()
        _ = result.forEachRow { row in

            session.token = row[0] as! String
            session.userId = row[1] as! UInt64
            session.created = Int(row[2] as! Int32)
            session.updated = Int(row[3] as! Int32)
            session.idle = Int(row[4] as! Int32)
            session.data = (try? JSONDecoder().decode([String:String].self, from: (row[5] as! String).data(using: .utf8)!)) ?? [:]
            session.ipAddress = row[6] as! String
            session.userAgent = row[7] as! String
            session.userCredentials = (try? JSONDecoder().decode(UserCredentials.self, from: (row[8] as! String).data(using: .utf8)!))
        }
        return session
    }
}

public extension HTTPRequest {
    var session: CSSession? {
        get {
            return scratchPad["CSSession"] as? CSSession
        }
        set {
            scratchPad["CSSession"] = newValue
        }
    }
}

// Some helpers
struct SessionHeader {
    // https://www.w3.org/TR/WD-session-id
    //Session-Id: SID:ANON:w3.org:j6oAOxCWZh/CD723LGeXlf-01 - SID:type:realm:identifier
    let headerValue: String

    init?(value: String?) {
        guard let value = value else { return nil }
        headerValue = value
    }

    var sessionid: String? {
        let parts = headerValue.components(separatedBy: ":")
        if parts.count < 4 { return nil }
        return parts[3]
    }
}

extension HTTPRequest {
    var sessionid: SessionHeader? {
        return SessionHeader(value: self.header(.custom(name: "Session-Id")))
    }

    public func getCookie(name: String) -> String? {
        for (cookieName, payload) in self.cookies {
            if name == cookieName {
                return payload
            }
        }
        return nil
    }
}
