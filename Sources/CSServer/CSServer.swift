import PerfectHTTPServer
import CSCoreView
import Foundation

public struct CSServer {
    public static var configuration: Configuration?
    public static var routes: CSRoutes.Type = CSRoutes.self
    public static var filters: CSFilters.Type = CSFilters.self
    
    public init(configuration c: Configuration) throws {
        let dbConfig = CSCoreDB(host: c.host, username: c.username, password: c.password, masterDatabase: c.masterDBName)
        CSServer.configuration = c
        CSCoreDBConfig.dbConfiguration = dbConfig
        try self.createMasterTables()
        self.addToRegister()
        try self.createClientDatabaseTables()
        CSServer.routes.load()
        CSServer.filters.load()
        // The name of the session.
        // This will also be the name of the cookie set in a browser.
        CSSessionConfig.name = "\(c.domain)Session"
        // The "Idle" time for the session, in seconds.
        // 86400 is one day.
        CSSessionConfig.idle = 86400
        // Optional cookie domain setting
        CSSessionConfig.cookieDomain = c.domain
        // Optional setting to lock session to the initiating IP address. Default is false
        CSSessionConfig.IPAddressLock = false
        // Optional setting to lock session to the initiating user agent string. Default is false
        CSSessionConfig.userAgentLock = false
        // The interval at which stale sessions are purged from the database
        CSSessionConfig.purgeInterval = 3600 // in seconds. Default is 1 hour.
        CSSessionConfig.CSRF.checkState = true
        CSSessionConfig.CSRF.acceptableHostnames = ["127.0.0.1"]
        CSSessionConfig.CORS.enabled = true
        CSSessionConfig.CORS.acceptableHostnames = ["*"]
    }
    public func start() throws {
        let server = HTTPServer()
        try CSSessionManager().setup()
        server.serverPort = 80
        server.serverName = "localhost"
        server.addRoutes(CSServer.routes.getAllRoutes())
        server.setRequestFilters(CSServer.filters.getRequestFilters())
        server.setResponseFilters(CSServer.filters.getResponseFilters())
        try server.start()
    }
    public func addToRegister() {
//        CSRegister.add(forKey: User.registerName, type: User.self)
        CSRegister.add(forKey: UserRole.registerName, type: UserRole.self)
    }
    private func createMasterTables() throws {
        try User.view(CSServer.configuration!.masterDBName).create()
        try Organization.view(CSServer.configuration!.masterDBName).create()
    }
    private func createClientDatabaseTables() throws {
        let organizations: [Organization] = try Organization.view(CSServer.configuration!.masterDBName).getAll() as! [Organization]
        for o in organizations {
            try CSLogger().create(database: o.dbName)
            try CSRegister.setup(withDatabase: o.dbName, host: CSServer.configuration!.host, username: CSServer.configuration!.username, password: CSServer.configuration!.password)
        }
    }
    
}

