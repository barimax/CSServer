import PerfectHTTPServer
import CSCoreView

public struct CSServer {
    static var configuration: Configuration?
    
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
    func addToRegister() {
        CSRegister.add(forKey: User.registerName, type: User.self)
        CSRegister.add(forKey: Organization.registerName, type: Organization.self)
    }
    public func start() throws {
        guard let c = CSServer.configuration else {
            throw AuthError.withDescription(message: "No configuration.")
        }
        self.addToRegister()
        do {
            try CSRegister.setup(withDatabase: c.masterDBName)
            try HTTPServer.launch(configurationData: self.confData)
        } catch {
            print("Network error thrown: \(error)")
        }
    }
    
}
