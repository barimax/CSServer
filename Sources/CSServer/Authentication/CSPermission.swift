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
        CSDynamicEntityPropertyDescription(name: "registerName", label: "Object"),
        CSDynamicEntityPropertyDescription(name: "permission", refRegisterName: "userAccessLevel", fieldType: .select, jsType: .number, colWidth: .normal, required: true, order: 1, label: "Permission")
    ]
    
    public var registerName: String
    public var permission: Int
}
