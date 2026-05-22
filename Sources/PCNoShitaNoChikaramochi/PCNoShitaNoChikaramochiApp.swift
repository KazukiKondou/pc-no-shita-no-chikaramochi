import AppKit
import Darwin

@main
@MainActor
struct PCNoShitaNoChikaramochiApp {
    static func main() {
        setvbuf(stdout, nil, _IOLBF, 0)
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
