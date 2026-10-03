import AppKit
import RightKitCore
import UniformTypeIdentifiers

/// 扩展主线程上的菜单呈现器。只缓存按外观绘制的符号；真实文件和应用图标仅在同次菜单内复用。
final class MenuRenderer {
    struct Result {
        let menu: NSMenu
        let commands: [Command]
    }

    private enum IconKey: Hashable {
        case app(String), fileType(String), file(String)
    }

    private var symbolAppearance: Bool?
    private var symbols: [String: NSImage] = [:]

    func render(_ nodes: [MenuNode], target: AnyObject?, action: Selector?, isDark: Bool) -> Result {
        if symbolAppearance != isDark {
            symbols.removeAll(keepingCapacity: true)
            symbolAppearance = isDark
        }
        var commands: [Command] = []
        var icons: [IconKey: NSImage] = [:]

        func image(for icon: MenuIcon) -> NSImage? {
            if case .symbol(let name) = icon {
                if let cached = symbols[name] { return cached.copy() as? NSImage }
                guard let source = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return nil }
                let rendered = Self.menuSymbol(source, isDark: isDark)
                symbols[name] = rendered
                return rendered.copy() as? NSImage
            }
            let key: IconKey
            switch icon {
            case .app(let id): key = .app(id)
            case .fileType(let ext): key = .fileType(ext)
            case .file(let path): key = .file(path)
            case .symbol: return nil
            }
            if let cached = icons[key] { return cached.copy() as? NSImage }
            let source: NSImage
            switch key {
            case .app(let id):
                guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return nil }
                source = NSWorkspace.shared.icon(forFile: url.path)
            case .fileType(let ext):
                source = NSWorkspace.shared.icon(for: UTType(filenameExtension: ext) ?? .data)
            case .file(let path):
                source = NSWorkspace.shared.icon(forFile: path)
            }
            let sized = Self.bitmap(NSSize(width: 16, height: 16)) { source.draw(in: $0) } ?? source
            icons[key] = sized
            return sized.copy() as? NSImage
        }

        func item(_ node: MenuNode) -> NSMenuItem {
            if node.content == .separator { return .separator() }
            let result = NSMenuItem(title: node.title, action: nil, keyEquivalent: "")
            result.image = node.icon.flatMap(image)
            switch node.content {
            case .command(let command):
                result.action = action
                result.target = target
                result.tag = commands.count
                commands.append(command)
            case .submenu(let children):
                let submenu = NSMenu(title: node.title)
                children.forEach { submenu.addItem(item($0)) }
                result.submenu = submenu
            case .separator: break
            }
            return result
        }

        let menu = NSMenu(title: "")
        nodes.forEach { menu.addItem(item($0)) }
        return Result(menu: menu, commands: commands)
    }

    /// 保留 Finder 对 SF Symbol 位图的浅深色兼容处理，外观变化时重画。
    private static func menuSymbol(_ symbol: NSImage, isDark: Bool) -> NSImage {
        guard let image = bitmap(symbol.size, draw: { rect in
            symbol.draw(in: rect)
            NSColor(white: isDark ? 1 : 0, alpha: 0.85).set()
            rect.fill(using: .sourceAtop)
        }) else { return symbol }
        image.isTemplate = true
        return image
    }

    /// 画成只有一张 2x 位图的图像。访达跨进程拷贝菜单时会编码图像的全部尺寸，
    /// 系统应用和文件图标直接交出去会触发从 16 到 1024 的整套图标生成。
    private static func bitmap(_ size: NSSize, draw: (NSRect) -> Void) -> NSImage? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }
        rep.size = size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        draw(NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }
}
