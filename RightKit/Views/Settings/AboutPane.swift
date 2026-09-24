import RightKitCore
import SwiftUI

/// 关于弹出层（设置窗口右上角）：品牌色只出现在图标里。
struct AboutPane: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return L("版本 %@（%@）", short, build)
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityLabel(L("RightKit 图标"))
            Text("RightKit")
                .font(.title2.weight(.semibold))
            Text(version)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Text(L("访达右键菜单工具。新建文件、复制移动、在应用中打开，以及一组文件工具。"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 320)
    }
}
