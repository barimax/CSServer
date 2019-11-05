import PerfectHTTPServer
import CSCoreView

struct CSServer {
    let server = HTTPServer()
    func addToRegister() {
        CSRegister.add(forKey: User.registerName, type: User.self)
        CSRegister.add(forKey: Organization.registerName, type: Organization.self)
    }
    func start() throws {
        try self.server.start()
    }
}
