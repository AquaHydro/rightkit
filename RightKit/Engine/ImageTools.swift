import AppKit
import CoreGraphics
import Foundation
import ImageIO
import RightKitCore
import UniformTypeIdentifiers

/// F-053 至 F-057。读写都用 ImageIO，输出写在源文件旁边，重名编号不覆盖。
enum ImageTools {
    enum Failure: Error, Equatable {
        case unreadable
        case writeFailed
        case iconutilFailed
        case file(FileEngineError)
    }

    static func load(_ url: URL) throws(Failure) -> (image: CGImage, properties: [CFString: Any]) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) > 0,
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { throw .unreadable }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        return (image, properties)
    }

    // MARK: F-053

    static func convert(_ url: URL, to format: ImageFormat) throws(Failure) -> URL {
        let (image, properties) = try load(url)
        let output: CGImage
        switch format {
        case .jpeg, .heic:
            // 不保留透明通道，透明处铺白。
            guard let flat = render(image, width: image.width, height: image.height, background: .white) else { throw .writeFailed }
            output = flat
        case .png, .tiff:
            output = image
        }
        var keep: [CFString: Any] = [:]
        if let orientation = properties[kCGImagePropertyOrientation] { keep[kCGImagePropertyOrientation] = orientation }
        let name = Naming.withExtension(Naming.removingExtension(url.lastPathComponent), format.fileExtension)
        return try write(output, type: type(of: format), properties: keep, in: url.deletingLastPathComponent(), as: name)
    }

    static func type(of format: ImageFormat) -> UTType {
        switch format {
        case .png: .png
        case .jpeg: .jpeg
        case .heic: .heic
        case .tiff: .tiff
        }
    }

    // MARK: F-054、F-055

    static let macIconPoints = [16, 32, 128, 256, 512]
    static let iOSIconPixels = [1024, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20]

    /// 返回 `.iconset` 和 `.icns` 的位置。
    static func makeMacIconSet(_ url: URL) throws(Failure) -> (iconset: URL, icns: URL) {
        let square = try squareImage(url)
        let parent = url.deletingLastPathComponent()
        let base = Naming.removingExtension(url.lastPathComponent)
        let temp = parent.appending(path: FileEngine.tempPrefix + UUID().uuidString + ".iconset", directoryHint: .isDirectory)
        let tempIcns = parent.appending(path: FileEngine.tempPrefix + UUID().uuidString + ".icns")
        defer {
            try? FileManager.default.removeItem(at: temp)
            try? FileManager.default.removeItem(at: tempIcns)
        }
        do {
            try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: false)
        } catch {
            throw .writeFailed
        }
        for points in macIconPoints {
            for scale in [1, 2] {
                let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
                try writePNG(square, size: points * scale, to: temp.appending(path: name))
            }
        }
        // 参数固定，文件名不进 shell。
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", temp.path(percentEncoded: false), "-o", tempIcns.path(percentEncoded: false)]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw .iconutilFailed
        }
        guard process.terminationStatus == 0 else { throw .iconutilFailed }
        do {
            let iconset = try FileEngine.place(temp, in: parent, as: base + ".iconset")
            let icns = try FileEngine.place(tempIcns, in: parent, as: Naming.removingExtension(iconset.lastPathComponent) + ".icns")
            return (iconset, icns)
        } catch {
            throw .file(error)
        }
    }

    static func makeIOSIconSet(_ url: URL) throws(Failure) -> URL {
        let square = try squareImage(url)
        let parent = url.deletingLastPathComponent()
        let temp = FileEngine.tempURL(in: parent)
        do {
            try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: false)
            for pixels in iOSIconPixels {
                try writePNG(square, size: pixels, to: temp.appending(path: "icon-\(pixels).png"))
            }
            return try FileEngine.place(temp, in: parent, as: Naming.iOSIconFolderName(forImage: url.lastPathComponent))
        } catch let failure as Failure {
            try? FileManager.default.removeItem(at: temp)
            throw failure
        } catch let error as FileEngineError {
            try? FileManager.default.removeItem(at: temp)
            throw .file(error)
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw .writeFailed
        }
    }

    /// 不是正方形时居中裁成正方形。
    static func squareImage(_ url: URL) throws(Failure) -> CGImage {
        let (image, _) = try load(url)
        let side = min(image.width, image.height)
        let rect = CGRect(x: (image.width - side) / 2, y: (image.height - side) / 2, width: side, height: side)
        guard let cropped = image.cropping(to: rect) else { throw .unreadable }
        return cropped
    }

    // MARK: F-056、F-057

    @MainActor
    static func setWallpaper(_ url: URL) -> Bool {
        guard let screen = NSScreen.screens.first else { return false }
        return (try? NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])) != nil
    }

    @MainActor
    static func setFolderIcon(folder: URL, image: URL) -> Bool {
        guard let icon = NSImage(contentsOf: image), icon.isValid else { return false }
        return NSWorkspace.shared.setIcon(icon, forFile: folder.path(percentEncoded: false), options: [])
    }

    // MARK: 绘制与写出

    static func render(_ image: CGImage, width: Int, height: Int, background: CGColor? = nil) -> CGImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.interpolationQuality = .high
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        if let background {
            context.setFillColor(background)
            context.fill(rect)
        }
        context.draw(image, in: rect)
        return context.makeImage()
    }

    static func writePNG(_ image: CGImage, size: Int, to url: URL) throws(Failure) {
        guard let scaled = render(image, width: size, height: size),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { throw .writeFailed }
        CGImageDestinationAddImage(destination, scaled, nil)
        guard CGImageDestinationFinalize(destination) else { throw .writeFailed }
    }

    private static func write(_ image: CGImage, type: UTType, properties: [CFString: Any], in folder: URL, as name: String) throws(Failure) -> URL {
        let temp = FileEngine.tempURL(in: folder)
        guard let destination = CGImageDestinationCreateWithURL(temp as CFURL, type.identifier as CFString, 1, nil) else {
            throw .writeFailed
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            try? FileManager.default.removeItem(at: temp)
            throw .writeFailed
        }
        do {
            return try FileEngine.place(temp, in: folder, as: name)
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw .file(error)
        }
    }
}
