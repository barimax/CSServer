import PerfectHTTPServer
import CSCoreView

public struct CSServer {
    public static var configuration: Configuration?
    
    let confData: [String:[[String:Any]]] = [
        "servers": [
            [
                "name":"localhost",
                "port":80,
                "routes":routes(),
                "filters":"",
            ]
        ]
    ]
    public init(configuration c: Configuration) throws {
        let dbConfig = CSCoreDB(host: c.host, username: c.username, password: c.password)
        CSServer.configuration = c
        CSCoreDBConfig.dbConfiguration = dbConfig
        self.addToRegister()
        try CSRegister.setup(withDatabase: c.masterDBName, configuration: dbConfig)
        try HTTPServer.launch(configurationData: self.confData)
    }
    func addToRegister() {
        CSRegister.add(forKey: User.registerName, type: User.self)
        CSRegister.add(forKey: Organization.registerName, type: Organization.self)
    }
    
    
}
