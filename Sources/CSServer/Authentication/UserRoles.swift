//
//  UserRoles.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 5.11.19.
//

import Foundation
import CSCoreView

public struct UserRole: CSEntityProtocol, CSOptionableEntityProtocol {
    public static var optionField: AnyKeyPath = \UserRole.name
    
    
    public static var registerName: String = "userRole"
    public static var singleName: String = "Role"
    public static var pluralName: String = "Roles"
    public static var tableName: String = "roles"
    public static var searchableFields: [AnyKeyPath] = [\UserRole.name]
    public static var fields: [CSPropertyDescription] = [
        CSPropertyDescription(keyPath: \UserRole.name, name: "name", label: "Role", ref: nil, fieldType: .text, jsType: .string, colWidth: .normal, required: true, order: 0),
        CSPropertyDescription(keyPath: \UserRole.permissions, name: "permissions", label: "Permissions", ref: CSPermissions.self, fieldType: .dynamicFormControl, jsType: .object, colWidth: .normal, required: true, order: 0)
    ]
    public var id: UInt64
    public var name: String
    public var permissions: [CSPermissions]
}
public enum UserAccessLevel: Int, CSOptionableEnumProtocol {
    public static var registerName: String = "userAccessLevel"
    
    case readOnly = 1
    case readWrite = 2
    case noAccess = 3
    
    public func getName() -> String? {
        switch self.rawValue {
        case 1:
            return "Read only"
        case 2:
            return "Full access"
        case 3:
            return "No access"
        default:
            return nil
        }
    }
}
