import PerfectHTTPServer
import CSCoreView
import Foundation

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
        CSSessionConfig.CSRF.acceptableHostnames = ["localhost"]
        CSSessionConfig.CORS.enabled = true
        CSSessionConfig.CORS.acceptableHostnames = ["*"]
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

