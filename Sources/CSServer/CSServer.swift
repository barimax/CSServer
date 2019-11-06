import PerfectHTTPServer
import CSCoreView

public struct CSServer {
    static var masterDBName: String = "masterDB"
    static var host: String = "127.0.0.1"
    static var username: String = "bmserver"
    static var password: String = "B@r1m@x2016"
    static let port: Int = 3306
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
    public func start() {
        self.addToRegister()
        do {
            try CSRegister.setup(withDatabase: CSServer.masterDBName)
            try HTTPServer.launch(configurationData: self.confData)
        } catch {
            print("Network error thrown: \(error)")
        }
    }
    public init() {}
}
