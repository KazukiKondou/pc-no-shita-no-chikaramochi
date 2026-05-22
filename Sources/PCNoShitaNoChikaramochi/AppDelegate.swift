import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var hostingView: NSHostingView<MenuBarCharacterView>?
    private let monitor = MemoryMonitor()
    private let animator = CharacterAnimator()
    private let appearance = AppearanceStore()

    private var usageMenuItem: NSMenuItem?
    private var stateMenuItem: NSMenuItem?
    private var bindTimer: Timer?

    private lazy var settingsController = SettingsWindowController(
        store: appearance,
        animator: animator,
        monitor: monitor
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        monitor.start()
        animator.start()

        setupMenuBar()

        // メニュー開いてる間も状態更新が走るよう .common モードで登録
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.animator.update(usage: self.monitor.usage)
                self.refreshMenu()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        bindTimer = t

        animator.update(usage: monitor.usage)
        refreshMenu()
    }

    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: 34)
        statusItem = item

        let view = MenuBarCharacterView(animator: animator, store: appearance)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 34, height: 22)
        hostingView = hosting

        if let button = item.button {
            button.subviews.forEach { $0.removeFromSuperview() }
            hosting.frame = button.bounds
            hosting.autoresizingMask = [.width, .height]
            button.addSubview(hosting)
        }

        let menu = NSMenu()
        let usage = NSMenuItem(title: "メモリ: --%", action: nil, keyEquivalent: "")
        usage.isEnabled = false
        let stateItem = NSMenuItem(title: "状態: --", action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        menu.addItem(usage)
        menu.addItem(stateItem)
        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "設定...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem(title: "PCの下の力持ちについて", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "終了", action: #selector(quit), keyEquivalent: "q")
        menu.addItem(quitItem)

        item.menu = menu
        usageMenuItem = usage
        stateMenuItem = stateItem
    }

    private func refreshMenu() {
        let usage = monitor.usage
        let usedGB = Double(monitor.usedBytes) / 1_073_741_824.0
        let totalGB = Double(monitor.totalBytes) / 1_073_741_824.0
        usageMenuItem?.title = String(format: "メモリ: %.1f%% (%.1f / %.1f GB)", usage, usedGB, totalGB)
        stateMenuItem?.title = "状態: \(animator.state.label)"
    }

    @objc private func showSettings() {
        settingsController.show()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "PCの下の力持ち"
        alert.informativeText = """
        メモリの使用率に応じて、キャラがダンベルやバーベルを上げ下げします。
        メニューバーで PC を支えてくれる小さな力持ちです。
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
