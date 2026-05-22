import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let store: AppearanceStore
    private let animator: CharacterAnimator
    private let monitor: MemoryMonitor

    init(store: AppearanceStore, animator: CharacterAnimator, monitor: MemoryMonitor) {
        self.store = store
        self.animator = animator
        self.monitor = monitor
    }

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(store: store, animator: animator, monitor: monitor)
        let hosting = NSHostingController(rootView: view)

        let w = NSWindow(contentViewController: hosting)
        w.styleMask = [.titled, .closable, .miniaturizable]
        w.title = "PCの下の力持ち の設定"
        w.isReleasedWhenClosed = false
        w.center()
        w.level = .normal

        window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
