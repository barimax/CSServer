import PerfectHTTPServer
import CSCoreView

struct CSServer {
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
    func start() {
        do {
            try HTTPServer.launch(configurationData: self.confData)
        } catch {
            print("Network error thrown: \(error)")
        }
    }
}
