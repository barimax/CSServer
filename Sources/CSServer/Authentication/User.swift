//
//  User.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//
import CSCoreView

struct User: CSEntityProtocol {
    static var registerName: String = "user"
    static var tableName: String = "users"
    static var singleName: String = "User"
    static var pluralName: String = "Users"
    static var searchableFields: [AnyKeyPath] = [\User.name, \User.email, \User.phone]
    static var fields: [CSPropertyDescription] = [
        CSPropertyDescription(keyPath: \User.organizationId, name: "organizationId", label: "Organization", ref: nil, fieldType: .select, jsType: .number, colWidth: .normal, required: true, order: 1),
        CSPropertyDescription(keyPath: \User.name, name: "name", label: "Name", ref: nil, fieldType: .text, jsType: .string, colWidth: .large, required: true, order: 2),
        CSPropertyDescription(keyPath: \User.email, name: "email", label: "E-mail", ref: nil, fieldType: .email, jsType: .string, colWidth: .normal, required: true, order: 3),
        CSPropertyDescription(keyPath: \User.password, name: "password", label: "Password", ref: nil, fieldType: .password, jsType: .string, colWidth: .normal, required: true, order: 4),
        CSPropertyDescription(keyPath: \User.phone,name: "phone", label: "Phone number", ref: nil, fieldType: .text, jsType: .string, colWidth: .normal, required: true, order: 5),
        CSPropertyDescription(keyPath: \User.userRole,name: "userRole", label: "Phone number", ref: UserRole.self, fieldType: .select, jsType: .number, colWidth: .normal, required: true, order: 6)
    ]
    
    var id: UInt64
    var organizationId: UInt64
    var name: String
    var email: String
    var password: String
    var phone: String
    var isLocked: Bool
    var userRole: Int
    var salt: String
    var validationString: String
}
