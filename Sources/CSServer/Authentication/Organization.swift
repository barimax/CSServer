//
//  Organization.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 1.11.19.
//
import Foundation
import PerfectCRUD
import PerfectMySQL
import PerfectLib
import CSCoreView

struct Organization: CSEntityProtocol {
    static var tableName: String = "organizations"
    static var registerName: String = "organization"
    static var singleName: String = "Organization"
    static var pluralName: String = "Organizations"
    static var searchableFields: [AnyKeyPath] = [\Organization.name, \Organization.eik]
    static var fields: [CSPropertyDescription] = [
        CSPropertyDescription(keyPath: \Organization.name, name: "name", label: "Name"),
        CSPropertyDescription(keyPath: \Organization.adddress, name: "address", label: "Address"),
        CSPropertyDescription(keyPath: \Organization.eik, name: "eik", label: "EIK"),
        CSPropertyDescription(keyPath: \Organization.mol, name: "mol", label: "MOL"),
        CSPropertyDescription(keyPath: \Organization.description, name: "description", label: "Description"),
    ]
    
    var id: UInt64
    var name: String
    var adddress: String
    var eik: String
    var mol: String
    var description: String
    var dbName: String
}
