import AppKit
import Darwin

@main
@MainActor
struct PCNoShitaNoChikaramochiApp {
    static func main() {
        setvbuf(stdout, nil, _IOLBF, 0)

        // 開発用: --render-previews <dir> で各状態を PNG 化して終了
        let args = CommandLine.arguments
        if let idx = args.firstIndex(of: "--render-previews") {
            let dir = idx + 1 < args.count ? args[idx + 1] : "preview-out"
            let url = URL(fileURLWithPath: dir)
            let count = PreviewRenderer.renderAll(to: url)
            print("rendered \(count) preview(s) to \(url.path)")
            exit(count > 0 ? 0 : 1)
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
