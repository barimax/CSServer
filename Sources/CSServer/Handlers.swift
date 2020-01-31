//
//  Handlers.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 5.11.19.
//

import Foundation
import PerfectHTTPServer
import PerfectHTTP
import CSCoreView

class CSMainHandlers {
    static func getUserRole(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            guard let db = request.session?.userCredentials?.organization.dbName else {
                throw CSViewError.registerError(message: "No database.")
            }
            let entity = try CSEntity(withType: UserRole.self, withDatabase: db)
            try response.setBody(json: entity)
            response.completed()
        } catch {
            response.status = .custom(code: 400, message: "\(error)")
        }
        response.completed()
    }
    static func getMenu(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            try response.setBody(json: CSMenu())
        } catch {
            response.status = .custom(code: 400, message: "\(error)")
        }
        response.completed()
    }
}

class CSCustomDataHandlers {
    static func get(request: HTTPRequest, _ response: HTTPResponse) {
        print("Get custom data entity/ies...")
        do {
            if let registerName: String = request.param(name: "registerName"),
                let db: String = request.session?.userCredentials?.organization.dbName {
                print(db)
                let customData: CSCustomData = try CSCustomData(database: db, registerName: registerName)
                var res: String = ""
                if let id: UInt64 = UInt64(request.param(name: "id") ?? "") {
                    res = try customData.get(id: id) ?? ""
                }else if let id: UInt64 = UInt64(request.param(name: "getAllId") ?? "") {
                    res = try customData.getAll(id: id) ?? ""
                }else{
                    res = try customData.getAll() ?? ""
                }
                response.setBody(string: res)
                response.setHeader(.contentType, value: "application/json")
                response.completed()
            }else{
                response.status = .badRequest
                response.completed()
            }
        }catch{
            response.status = .badRequest
            response.completed()
        }
    }
    static func save(request: HTTPRequest, _ response: HTTPResponse) {
        print("Save custom data entity")
        do {
            if let registerName: String = request.param(name: "registerName"),
                let db: String = request.session?.userCredentials?.organization.dbName,
                let postBody = request.postBodyString {
                let customData: CSCustomData = try CSCustomData(database: db, registerName: registerName)
                if let saved = try customData.save(json: postBody) {
                    response.setBody(string: saved)
                    response.setHeader(.contentType, value: "application/json")
                    response.completed()
                }else{
                    response.status = .badRequest
                    response.completed()
                }
            }else{
                response.status = .badRequest
                response.completed()
            }
        }catch{
            print(error)
            response.status = .custom(code: 400, message: "\(error)")
            response.completed()
        }
    }
    static func create(request: HTTPRequest, _ response: HTTPResponse) {
        struct CSCustomDataCreateRequest: Codable {
            let registerName: String
            let fields: [CSDynamicEntityPropertyDescription]
        }
        do {
            if let reqBody = request.postBodyString,
                let db: String = request.session?.userCredentials?.organization.dbName {
                let req = try JSONDecoder().decode(CSCustomDataCreateRequest.self, from: reqBody.data(using: .utf8)!)
                try CSCustomData.create(registerName: req.registerName, fields: req.fields, database: db)
                response.completed()
            }else{
                response.status = .badRequest
                response.completed()
            }
        }catch{
            print(error)
            response.status = .custom(code: 400, message: "\(error)")
            response.completed()
        }
    }
    
    static func new(request: HTTPRequest, _ response: HTTPResponse) {
        struct newResponse: Encodable {
            let filedTypes: [String] = FieldType.allCases.map { $0.rawValue }
            let colWidths: [Int] = ColWidth.allCases.map { $0.rawValue }
            let jsTypes: [String] = JSType.allCases.map { $0.rawValue }
        }
        let n = newResponse()
        do {
            try response.setBody(json: n)
            response.completed()
        }catch{
            print(error)
            response.status = .custom(code: 400, message: "\(error)")
            response.completed()
        }
    }
}
