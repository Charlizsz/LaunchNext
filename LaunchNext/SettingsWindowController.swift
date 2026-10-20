import AppKit
import SwiftUI
import SwiftData

/// A separate, movable settings window sharing the launcher's live AppStore.
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let appStore: AppStore
    private let modelContainer: ModelContainer?
    private var window: NSWindow?

    init(appStore: AppStore, modelContainer: ModelContainer?) {
        self.appStore = appStore
        self.modelContainer = modelContainer
    }

    func show(relativeTo launcher: NSWindow?) {
        if let window {
            launcher?.orderFrontRegardless()
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
            return
        }
        let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 860, height: 680),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable],
                             backing: .buffered, defer: false)
        panel.title = appStore.localized(.settingsWindowTitle)
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentMinSize = NSSize(width: 820, height: 640)
        panel.level = launcher?.level ?? .floating
        panel.collectionBehavior = [.fullScreenAuxiliary]
        panel.appearance = launcher?.appearance
        let view = SettingsView(appStore: appStore)
        if let modelContainer {
            panel.contentView = NSHostingView(rootView: view.modelContainer(modelContainer))
        } else {
            panel.contentView = NSHostingView(rootView: view)
        }
        if !panel.setFrameUsingName("LaunchNextSettingsWindow") {
            if let screen = launcher?.screen ?? NSScreen.main {
                let available = screen.visibleFrame
                let anchor = launcher?.frame ?? available
                let width = panel.frame.width
                let x: CGFloat
                if anchor.maxX + 16 + width <= available.maxX {
                    x = anchor.maxX + 16
                } else if anchor.minX - 16 - width >= available.minX {
                    x = anchor.minX - 16 - width
                } else {
                    x = max(available.minX, available.maxX - width - 16)
                }
                panel.setFrameOrigin(NSPoint(x: x, y: max(available.minY, available.maxY - panel.frame.height - 24)))
            } else {
                panel.center()
            }
        }
        panel.setFrameAutosaveName("LaunchNextSettingsWindow")
        window = panel
        panel.makeKeyAndOrderFront(nil)
        // The launcher is a transient borderless window. Reorder it without
        // taking key focus so AppKit keeps it visible beside settings.
        launcher?.orderFrontRegardless()
        panel.orderFrontRegardless()
    }

    func close() { window?.close() }

    func updateLevel(_ level: NSWindow.Level) { window?.level = level }

    func updateAppearance(_ appearance: NSAppearance?) { window?.appearance = appearance }

    func windowWillClose(_ notification: Notification) {
        // Removing the hosting view also ends shortcut capture in SettingsView.
        window?.contentView = nil
        window = nil
        if appStore.isSetting { appStore.isSetting = false }
        if let launcher = AppDelegate.shared?.launchpadWindow, launcher.isVisible {
            launcher.makeKeyAndOrderFront(nil)
        }
    }
}
