//
//  UserRoles.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 5.11.19.
//

import Foundation
import CSCoreView

enum UserRole: Int, CSOptionableEnumProtocol {
    static var registerName: String = "userRole"
    
    case admin = 1
    case superUser = 2
    case user = 3
    case client = 4
    case partner = 5
    
    func getName() -> String? {
        switch self.rawValue {
        case 1:
            return "Administrator"
        case 2:
            return "Superuser"
        case 3:
            return "User"
        case 4:
            return "Client"
        case 5:
            return "Partner"
        default:
            return nil
        }
    }
}
enum UserAccessLevel: Int, CSOptionableEnumProtocol {
    static var registerName: String = "userAccessLevel"
    
    case readOnly = 1
    case readWrite = 2
    case noAccess = 3
    
    func getName() -> String? {
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
