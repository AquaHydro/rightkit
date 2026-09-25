import RightKitCore
import SwiftUI

/// 首次启动的欢迎窗口，单页：Riko、说明、启用访达扩展、文件夹授权、登录时启动和菜单栏开关。
struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    let windows: WindowOpener
    /// 在这个窗口里授权的监视目录；「更改…」替换的就是它（F-080）。
    @State private var authorizedID: UUID?
    @State private var rejected = false

    private var authorized: FolderEntry? {
        model.settings.monitoredFolders.first { $0.id == authorizedID }
    }

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 20) {
            CharacterAvatar(name: "WelcomeCharacter", size: 160)
            VStack(spacing: 8) {
                Text(L("欢迎使用 RightKit"))
                    .font(.largeTitle.weight(.semibold))
                Text(L("在访达里右键，就能新建文件、把项目复制或移动到常用位置、用指定应用打开，以及使用一组文件工具。"))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 380)
            }
            ExtensionStatusCard()
                .padding(12)
                .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))
                .frame(width: 400)
            Form {
                Section {
                    HStack {
                        RowLabel(title: L("授权访问个人文件夹"),
                                 caption: authorized.map { L("%@ 已授权", FolderStore.displayName($0)) }
                                     ?? L("RightKit 只能在你授权的文件夹里新建、复制和整理文件。建议授权个人主文件夹。"),
                                 symbol: "folder.badge.person.crop", tint: .intentGo)
                        Spacer()
                        Button(authorized == nil ? L("授权…") : L("更改…"), action: authorize)
                    }
                    // F-005：初始为关，由用户自己打开。
                    Toggle(isOn: $model.settings.launchAtLogin) {
                        RowLabel(title: L("登录时启动"), caption: L("让 RightKit 随登录运行，右键操作即点即用。"),
                                 symbol: "power", tint: .intentCreate)
                    }
                    Toggle(isOn: $model.settings.showMenuBarIcon) {
                        RowLabel(title: L("显示菜单栏图标"), symbol: "menubar.rectangle", tint: .intentInspect)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(width: 440)
            .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button(L("稍后设置")) { finish(openSettings: false) }
                    .controlSize(.large)
                Button(L("开始使用")) { finish(openSettings: true) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .fixedSize()
        .alert(L("无法监视这个文件夹"), isPresented: $rejected) {
            Button(L("好")) {}
        } message: {
            Text(L("不能添加根目录、系统目录，或个人主目录的上级目录。"))
        }
    }

    /// F-080：面板从主目录开始；选中的文件夹加入监视目录并完成授权。
    private func authorize() {
        let start = authorized.map { URL(filePath: $0.path, directoryHint: .isDirectory) }
            ?? URL(filePath: FolderStore.home, directoryHint: .isDirectory)
        guard let url = Alerts.chooseFolder(prompt: L("授权"), startingAt: start) else { return }
        guard PathRules.canMonitor(url.path(percentEncoded: false), home: FolderStore.home) else { return rejected = true }
        if let authorized {
            model.reauthorize(authorized, in: \.monitoredFolders, with: url)
        } else {
            model.addMonitoredFolder(url)
            let path = PathRules.standardized(url.path(percentEncoded: false))
            authorizedID = model.settings.monitoredFolders.first { PathRules.standardized($0.path) == path }?.id
        }
    }

    private func finish(openSettings: Bool) {
        model.settings.welcomeShown = true
        dismissWindow(id: WindowID.welcome)
        if openSettings { windows.openSettings() }
    }
}
