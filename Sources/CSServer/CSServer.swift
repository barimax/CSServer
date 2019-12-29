import PerfectHTTPServer
import CSCoreView
import Foundation
import PerfectSession
import PerfectSessionMySQL

public struct CSServer {
    public static var configuration: Configuration?
    public static var routes: CSRoutes.Type = CSRoutes.self
    public static var filters: CSFilters.Type = CSFilters.self
    
    public init(configuration c: Configuration) throws {
        let dbConfig = CSCoreDB(host: c.host, username: c.username, password: c.password)
        CSServer.configuration = c
        CSCoreDBConfig.dbConfiguration = dbConfig
        self.addToRegister()
        try CSRegister.setup(withDatabase: c.masterDBName, configuration: dbConfig)
        Self.routes.load()
        Self.filters.load()
        // The name of the session.
        // This will also be the name of the cookie set in a browser.
        SessionConfig.name = "\(c.domain)Session"
        // The "Idle" time for the session, in seconds.
        // 86400 is one day.
        SessionConfig.idle = 86400
        // Optional cookie domain setting
        SessionConfig.cookieDomain = c.domain
        // Optional setting to lock session to the initiating IP address. Default is false
        SessionConfig.IPAddressLock = false
        // Optional setting to lock session to the initiating user agent string. Default is false
        SessionConfig.userAgentLock = false
        // The interval at which stale sessions are purged from the database
        SessionConfig.purgeInterval = 3600 // in seconds. Default is 1 hour.
        MySQLSessionConnector.host = dbConfig.host
        MySQLSessionConnector.port = dbConfig.port
        MySQLSessionConnector.username = dbConfig.username
        MySQLSessionConnector.password = dbConfig.password
        MySQLSessionConnector.database = c.masterDBName
        MySQLSessionConnector.table = "sessions"
    }
    public func start() throws {
        let server = HTTPServer()
        CSSessionManager().setup()
        server.serverPort = 80
        server.serverName = "localhost"
        server.addRoutes(Self.routes.getAllRoutes())
        server.setRequestFilters(Self.filters.getRequestFilters())
        server.setResponseFilters(Self.filters.getResponseFilters())
        try server.start()
    }
    public func addToRegister() {
        CSRegister.add(forKey: User.registerName, type: User.self)
        CSRegister.add(forKey: Organization.registerName, type: Organization.self)
    }
    
    
}

