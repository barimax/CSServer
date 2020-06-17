//
//  User.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//
import CSCoreView
import Foundation

public struct User: CSEntityProtocol, CSOptionableEntityProtocol {
    public static var optionField: AnyKeyPath = \User.email
    
    
    public static var registerName: String = "user"
    public static var tableName: String = "users"
    public static var singleName: String = "User"
    public static var pluralName: String = "Users"
    public static var searchableFields: [AnyKeyPath] = [\User.name, \User.email, \User.phone]
    public static var fields: [CSPropertyDescription] = [
        CSPropertyDescription(keyPath: \User.name, name: "name", label: "Name", ref: nil, fieldType: .text, jsType: .string, colWidth: .large, required: true, order: 1),
        CSPropertyDescription(keyPath: \User.email, name: "email", label: "E-mail", ref: nil, fieldType: .email, jsType: .string, colWidth: .normal, required: true, order: 2),
        CSPropertyDescription(keyPath: \User.phone,name: "phone", label: "Phone number", ref: nil, fieldType: .text, jsType: .string, colWidth: .normal, required: true, order: 3),
        CSPropertyDescription(keyPath: \User.userRole,name: "userRole", label: "Role", ref: UserRole.self, fieldType: .select, jsType: .number, colWidth: .normal, required: true, order: 4)
    ]
    
    public var id: UInt64
    var organizationId: UInt64
    var name: String
    var email: String
    var password: String
    var phone: String
    var isLocked: Bool = false
    var userRole: UInt64
    var salt: String
    var validationString: String
    var timestamp: Date?
    
    struct UserForm: Codable {
        var id: UInt64
        var name: String
        var email: String
        var phone: String
        var userRole: UInt64
    }
//    // Codable keys
//    enum CodingKeys: String, CodingKey {
//        case id, name, email, phone, userRole
//    }
//    // Encodable conformance
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(name, forKey: .name)
//        try container.encode(id, forKey: .id)
//        try container.encode(email, forKey: .email)
//        try container.encode(phone, forKey: .phone)
//        try container.encode(userRole, forKey: .userRole)
//    }
//    // Decodable conformance
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        id = try values.decodeIfPresent(UInt64.self, forKey: .id) ?? 0
//        name =  try values.decodeIfPresent(String.self, forKey: .name) ?? ""
//        email = try values.decodeIfPresent(String.self, forKey: .email) ?? ""
//        phone = try values.decodeIfPresent(String.self, forKey: .phone) ?? ""
//        userRole = try values.decodeIfPresent(UInt64.self, forKey: .id) ?? 0
//        timestamp =  Date()
//    }
}
