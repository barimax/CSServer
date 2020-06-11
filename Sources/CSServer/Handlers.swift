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
import PerfectMySQL
import PerfectCRUD

class CSMainHandlers {
    static public func staticTemplateFile(request: HTTPRequest, _ response: HTTPResponse) {
        request.path = request.urlVariables[routeTrailingWildcardKey] ?? "/"
        let handler = StaticFileHandler(documentRoot: "./\(CSServer.configuration!.template)", allowResponseFilters: true)
        if Configuration.production {
            response.addHeader(HTTPResponseHeader.Name.cacheControl, value: "max-age=31536000")
        }
        handler.handleRequest(request: request, response: response)
    }
    static public func staticWebrootFile(request: HTTPRequest, _ response: HTTPResponse) {
        request.path = request.urlVariables[routeTrailingWildcardKey] ?? "/"
        let handler = StaticFileHandler(documentRoot: "./\(CSServer.configuration!.webroot)", allowResponseFilters: true)
        if Configuration.production {
            response.addHeader(HTTPResponseHeader.Name.cacheControl, value: "max-age=31536000")
        }
        handler.handleRequest(request: request, response: response)
    }
    static func getUserRole(request: HTTPRequest, _ response: HTTPResponse) {
        do {
            guard let db = request.session?.userCredentials?.organization.dbName else {
                throw CSViewError.registerError(message: "No database.")
            }
            let entity = CSEntity(withType: UserRole.self, withDatabase: db)
            try response.setBody(json: entity)
            response.completed()
        } catch {
            response.status = .custom(code: 400, message: "\(error)")
        }
        response.completed()
    }
    static func getMenu(request: HTTPRequest, _ response: HTTPResponse) {
        response.sendResponse(body: CSMenu(), responseType: .json)
    }
    static func getEntity(request: HTTPRequest, _ response: HTTPResponse) {
        guard let registerName: String = request.param(name: "registerName"),
            let db: String = request.session?.userCredentials?.organization.dbName else {
            response.status = .badRequest
            response.completed()
            return
        }
        do {
            let entity = try CSEntity(registerName: registerName, database: db)
            if let strId = request.param(name: "id"),
                let id: UInt64 = UInt64(strId) {
                try entity.load(id: id)
            }
            if let _ = request.param(name: "all"){
                try entity.loadAll()
            }
            response.sendResponse(body: entity, responseType: .json)
        } catch {
            response.status = .custom(code: 400, message: "\(error)")
        }
        response.completed()
    }
    static func findEntity(request: HTTPRequest, _ response: HTTPResponse) {
        guard let registerName: String = request.param(name: "registerName"),
            let db: String = request.session?.userCredentials?.organization.dbName else {
            response.status = .badRequest
            response.completed()
            return
        }
        do {
            let entity = try CSEntity(registerName: registerName, database: db)
            if let body = request.postBodyString {
                if let data = body.data(using: .utf8),
                let criteria: [String: String] = try? JSONDecoder().decode([String:String].self, from: data) {
                print(criteria)
                entity.rows = entity.find(criteria: criteria)
                }
            }
            response.sendResponse(body: entity, responseType: .json)
        } catch {
            response.status = .custom(code: 400, message: "\(error)")
        }
        response.completed()
    }
    static func saveEntity(request: HTTPRequest, _ response: HTTPResponse) {
        guard let registerName: String = request.param(name: "registerName"),
            let db: String = request.session?.userCredentials?.organization.dbName,
            let body: String = request.postBodyString else {
            response.status = .badRequest
            response.completed()
            return
        }
        do {
            let entity = try CSEntity(registerName: registerName, encodedEntity: body, database: db)
            try entity.saveAndLoad()
            response.sendResponse(body: entity, responseType: .json)
        } catch {
            response.status = .custom(code: 400, message: "\(error)")
        }
        response.completed()
    }
}

class CSUserHandlers {
    static func getUsers(request: HTTPRequest, _ response: HTTPResponse) {
        guard let organization = request.session?.userCredentials?.organization else {
            response.completed(status: .unauthorized)
            return
        }
        do {
            let view = User.view(organization.dbName)
            let userEntity = CSEntity(view: view, registerName: User.registerName)
            let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
                MySQLDatabaseConfiguration(
                    database: CSServer.configuration!.masterDBName,
                    host: CSServer.configuration!.host,
                    port: CSServer.configuration!.port,
                    username: CSServer.configuration!.username,
                    password: CSServer.configuration!.password)
            )
            userEntity.rows = try db.table(User.self).where(\User.organizationId == organization.id).select().map { return $0 }
            response.sendResponse(body: userEntity, responseType: .json, viewType: .adminView)
        } catch {
            response.status = .custom(code: 400, message: "\(error)")
        }
        response.completed()
    }
    static func saveUser(request: HTTPRequest, _ response: HTTPResponse) {
        guard let organization = request.session?.userCredentials?.organization,
            let body: String = request.postBodyString,
            let data: Data = body.data(using: .utf8) else {
            response.completed(status: .unauthorized)
            return
        }
        do {
            let userForm: User.UserForm = try JSONDecoder().decode(User.UserForm.self, from: data )
            let view = User.view(organization.dbName)
            let userEntity = CSEntity(view: view, registerName: User.registerName)
            let db: Database<MySQLDatabaseConfiguration> = try Database(configuration:
                MySQLDatabaseConfiguration(
                    database: CSServer.configuration!.masterDBName,
                    host: CSServer.configuration!.host,
                    port: CSServer.configuration!.port,
                    username: CSServer.configuration!.username,
                    password: CSServer.configuration!.password)
            )
            if userForm.id > 0 {
                guard var user: User = try db.table(User.self).where(\User.id == userForm.id).first() else {
                    response.completed(status: .badRequest)
                    return
                }
                if user.email != userForm.email {
                    user.isLocked = true
                    Utility().sendMail(
                        name: organization.name,
                        address: userForm.email,
                        subject: "Validate email",
                        html: try Authentication().conformationEmail(validationString: user.validationString),
                        text: ""
                    )
                }
                user.email = userForm.email
                user.phone = userForm.phone
                user.name = userForm.name
                user.userRole = userForm.userRole
                try db.table(User.self).where(\User.id == user.id).update(user)
                userEntity.entity = user
            }else{
                let user = User(id: 0,
                                organizationId: organization.id,
                                name: userForm.name,
                                email: userForm.email,
                                password: "",
                                phone: userForm.phone,
                                isLocked: true,
                                userRole: userForm.userRole,
                                salt: String(randomWithLength: 14),
                                validationString: String(randomWithLength: 20),
                                timestamp: Date()
                )
                if try db.table(User.self).where(\User.email == userForm.email).count() > 0 {
                    throw AuthError.userExist
                }
                try db.table(User.self).insert(user)
                Utility().sendMail(
                    name: organization.name,
                    address: user.email,
                    subject: "Validate email",
                    html: try Authentication().conformationEmail(validationString: user.validationString),
                    text: ""
                )
                userEntity.entity = user
            }
            userEntity.rows = try db.table(User.self).where(\User.organizationId == organization.id).select().map { return $0 }
            response.sendResponse(body: userEntity, responseType: .json, viewType: .adminView)
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
