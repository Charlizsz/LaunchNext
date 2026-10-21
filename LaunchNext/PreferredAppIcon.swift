import AppKit

/// Read only the application's icon choice; never modify its preferences/bundle.
nonisolated enum PreferredAppIcon {
    static let domain = "com.openai.codex"

    static func resourceName() -> String? {
        guard let name = CFPreferencesCopyAppValue("DockIconResourceName" as CFString, domain as CFString) as? String,
              !name.isEmpty, (name as NSString).lastPathComponent == name,
              ["png", "icns"].contains((name as NSString).pathExtension.lowercased()) else { return nil }
        return name
    }

    static func selectionToken() -> String {
        CFPreferencesAppSynchronize(domain as CFString)
        let telegram = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "ru.keepcoder.Telegram")
        return (resourceName() ?? "") + "|" + (telegram.map(customIconToken) ?? "")
    }

    /// Telegram stores its chosen icon in the standard Finder custom-icon resource fork.
    static func customIconToken(for appURL: URL) -> String {
        guard Bundle(url: appURL)?.bundleIdentifier == "ru.keepcoder.Telegram" else { return "" }
        let icon = appURL.appendingPathComponent("Icon\r")
        var info = stat()
        guard stat(icon.path, &info) == 0 else { return "" }
        return "\(info.st_ino):\(info.st_ctimespec.tv_sec):\(info.st_ctimespec.tv_nsec)"
    }

    private static func attribute(_ name: String, at url: URL, limit: Int) -> Data? {
        let count = getxattr(url.path, name, nil, 0, 0, 0)
        guard count > 0, count <= limit else { return nil }
        var data = Data(count: count)
        let read = data.withUnsafeMutableBytes { getxattr(url.path, name, $0.baseAddress, count, 0, 0) }
        return read == count ? data : nil
    }

    static func customIcon(for appURL: URL) -> NSImage? {
        guard Bundle(url: appURL)?.bundleIdentifier == "ru.keepcoder.Telegram",
              let flags = attribute("com.apple.FinderInfo", at: appURL, limit: 256),
              flags.count > 8, flags[8] & 4 != 0,
              let fork = attribute("com.apple.ResourceFork", at: appURL.appendingPathComponent("Icon\r"), limit: 10 * 1024 * 1024),
              let data = iconData(in: fork) else { return nil }
        return NSImage(data: data)
    }

    /// Resolve the icns entry through the resource map, with bounds checks for damaged files.
    static func iconData(in data: Data) -> Data? {
        func number(_ offset: Int, _ count: Int) -> Int? {
            guard offset >= 0, count <= data.count, offset <= data.count - count else { return nil }
            return data[offset..<(offset + count)].reduce(0) { ($0 << 8) | Int($1) }
        }
        guard let dataStart = number(0, 4), let mapStart = number(4, 4),
              let typeOffset = number(mapStart + 24, 2) else { return nil }
        let types = mapStart + typeOffset
        guard let typeCount = number(types, 2), typeCount < 1024 else { return nil }
        for index in 0...typeCount {
            let entry = types + 2 + index * 8
            guard let type = number(entry, 4), let referenceOffset = number(entry + 6, 2) else { return nil }
            guard type == 0x69636e73 else { continue }
            let reference = types + referenceOffset
            guard let offset = number(reference + 5, 3), let length = number(dataStart + offset, 4) else { return nil }
            let start = dataStart + offset + 4
            guard length >= 8, start <= data.count, length <= data.count - start,
                  number(start, 4) == 0x69636e73, number(start + 4, 4) == length else { return nil }
            return data.subdata(in: start..<(start + length))
        }
        return nil
    }

    static func resourceURL(for appURL: URL) -> URL? {
        guard let bundle = Bundle(url: appURL), bundle.bundleIdentifier == domain,
              let name = resourceName(), let resources = bundle.resourceURL else { return nil }
        let url = resources.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
