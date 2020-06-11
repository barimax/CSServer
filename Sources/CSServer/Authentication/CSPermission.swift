//
//  CSPermission.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 30.01.20.
//
import CSCoreView

public struct CSPermissions: CSDynamicFieldProtocol {
    public static var isButton: Bool = false
    public static var registerName: String = "permission"
    public static var singleName: String = "Permission"
    public static var pluralName: String = "Permissions"
    public static var tableName: String = "permissions"
    public static var searchableFields: [AnyKeyPath] = []
    public static var fields: [CSDynamicEntityPropertyDescription] = [
        CSDynamicEntityPropertyDescription(name: "registerName", ref: nil, fieldType: .hidden, jsType: .string, colWidth: .small, required: true, order: 0, label: "", disabled: true),
        CSDynamicEntityPropertyDescription(name: "pluralName", ref: nil, fieldType: .text, jsType: .string, colWidth: .small, required: true, order: 1, label: "Object", disabled: true),
        CSDynamicEntityPropertyDescription(name: "permission", ref: UserAccessLevel.self, fieldType: .radio, jsType: .number, colWidth: .normal, required: true, order: 2, label: "Permission")
    ]
    public static var defaultValue: [CSDynamicFieldEntityProtocol]? {
        return CSRegister.store.map { return CSPermission(registerName: $0.key, pluralName: $0.value.pluralName, permission: UserAccessLevel.readWrite.rawValue) }
    }
    public struct CSPermission: CSDynamicFieldEntityProtocol {
        public var registerName: String
        public var pluralName: String
        public var permission: Int
    }
    public var value: [CSDynamicFieldEntityProtocol]
    
    
    // Codable keys
    enum CodingKeys: String, CodingKey {
        case value
    }
    // Encodable conformance
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.value.map { EncodableWrapper($0) }, forKey: .value)
    }
    // Decodable conformance
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        value = try values.decodeIfPresent([CSPermission].self, forKey: .value) ?? []
    }
}


