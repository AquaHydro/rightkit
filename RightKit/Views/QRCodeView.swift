import Observation
import RightKitCore
import SwiftUI
import UniformTypeIdentifiers

/// 系统服务和快捷指令共用的二维码窗口内容。
@MainActor @Observable
final class QRModel {
    var text = ""
}

struct QRCodeView: View {
    @Environment(QRModel.self) private var model
    @State private var saveFailed = false

    var body: some View {
        @Bindable var model = model
        let image = QRCode.image(for: model.text)
        VStack(spacing: 12) {
            Group {
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .interpolation(.none)
                        .accessibilityLabel(L("二维码预览"))
                } else {
                    ContentUnavailableView(L("输入文本以生成二维码"), systemImage: "qrcode")
                }
            }
            .frame(width: 240, height: 240)
            .animation(.default, value: image == nil)

            TextField(L("文本"), text: $model.text, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button(L("拷贝图片"), action: copyImage)
                Button(L("存储为 PNG…"), action: save)
            }
            .disabled(model.text.isEmpty)
        }
        .padding(20)
        .frame(width: 320)
        .alert(L("无法保存二维码。"), isPresented: $saveFailed) { Button(L("好")) {} }
    }

    private func copyImage() {
        guard let data = QRCode.pngData(for: model.text) else { return saveFailed = true }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
    }

    private func save() {
        guard let data = QRCode.pngData(for: model.text) else { return saveFailed = true }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = L("二维码") + ".png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            saveFailed = true
        }
    }
}
