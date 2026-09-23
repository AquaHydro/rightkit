import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// F-070：本机生成二维码，不上传文本。
enum QRCode {
    /// 每个模块放大成整数像素，保持边缘清晰。
    static func image(for text: String, moduleSize: Int = 12) -> CGImage? {
        guard !text.isEmpty else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: CGFloat(moduleSize), y: CGFloat(moduleSize)))
        // 四周留两个模块宽的空白，便于扫描。
        let margin = CGFloat(moduleSize * 2)
        let padded = scaled.composited(over: CIImage(color: .white).cropped(to: scaled.extent.insetBy(dx: -margin, dy: -margin)))
        return CIContext().createCGImage(padded, from: padded.extent)
    }

    static func pngData(for text: String) -> Data? {
        guard let image = image(for: text) else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }

    /// 用于验收：把图里的二维码读回文本。
    static func decode(_ image: CGImage) -> String? {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        return (detector?.features(in: CIImage(cgImage: image)).first as? CIQRCodeFeature)?.messageString
    }
}
