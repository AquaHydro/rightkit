import RightKitCore
import SwiftUI

/// 关于弹出层（设置窗口右上角）：应用图标（Q 版 Riko）、版本、标语和链接。
/// 官网版有 GitHub、反馈问题和检查更新；商店版只有反馈问题（F-082）。
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
                .accessibilityHidden(true)
            VStack(spacing: 4) {
                Text("RightKit")
                    .font(.title2.weight(.semibold))
                Text(version)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Text(L("右键一下，就办好了。"))
                .font(.headline)
            Text(L("访达右键菜单工具。新建文件、复制移动、在应用中打开，以及一组文件工具。"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            #if APP_STORE
            // 仓库私有期间，商店版反馈走邮件；不提供外部更新入口。
            Link(L("反馈问题"), destination: URL(string: "mailto:contact@yiliang.me")!)
                .font(.callout)
            #else
            HStack(spacing: 16) {
                Link("GitHub", destination: URL(string: "https://github.com/AquaHydro/rightkit")!)
                Link(L("反馈问题"), destination: URL(string: "https://github.com/AquaHydro/rightkit/issues")!)
            }
            .font(.callout)
            Button(L("检查更新…")) { UpdateChecker.shared.checkNow() }
            #endif
        }
        .padding(24)
        .frame(width: 320)
    }
}
