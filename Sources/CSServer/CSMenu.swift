//
//  CSMenu.swift
//  COpenSSL
//
//  Created by Georgie Ivanov on 27.01.20.
//

public struct CSMenu: Codable {
    public static var menu: [CSMenuMainItem] = []
    var menu: [CSMenuMainItem] = CSMenu.menu
}
public struct CSMenuMainItem: Codable {
    let label: String
    public var submenuItems: [CSMenuSubItem] = []
    
    public init(label: String){
        self.label = label
    }
}
public struct CSMenuSubItem: Codable {
    let label: String
    let registerName: String
    
    public init(label: String, registerName: String){
        self.label = label
        self.registerName = registerName
    }
}
