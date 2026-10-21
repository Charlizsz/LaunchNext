import Foundation
import AppKit

final class IconStore {
    static let shared = IconStore()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 200
    }

    func icon(for app: AppInfo) -> NSImage {
        if let selected = preferredIcon(forPath: app.url.path) { return selected }
        if PerformanceMode.current == .full {
            return app.icon
        }
        return icon(forPath: app.url.path)
    }

    func preferredIcon(forPath path: String) -> NSImage? {
        let appURL = URL(fileURLWithPath: path)
        let customToken = PreferredAppIcon.customIconToken(for: appURL)
        if !customToken.isEmpty {
            let key = (path + "|custom|" + customToken) as NSString
            if let cached = cache.object(forKey: key) { return cached }
            if let image = PreferredAppIcon.customIcon(for: appURL), image.isValid {
                cache.setObject(image, forKey: key)
                return image
            }
        }
        guard let resource = PreferredAppIcon.resourceURL(for: appURL) else { return nil }
        let key = (path + "|selected|" + resource.path) as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = NSImage(contentsOf: resource), image.isValid else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    func icon(forPath path: String) -> NSImage {
        if let selected = preferredIcon(forPath: path) { return selected }
        let key = path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let icon = NSWorkspace.shared.icon(forFile: path)
        cache.setObject(icon, forKey: key)
        return icon
    }

    func clear() {
        cache.removeAllObjects()
        FolderIconBitmapCache.shared.clear()
    }
}

final class FolderPreviewCache {
    static let shared = FolderPreviewCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 120
    }

    func image(forKey key: String) -> NSImage? {
        cache.object(forKey: key as NSString)
    }

    func store(_ image: NSImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func clear() {
        cache.removeAllObjects()
    }
}
