import RightKitCore
import SwiftUI

/// F-020 至 F-023。
struct OpenInPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Pane {
            Section {
                ForEach($model.settings.openTools) { $tool in
                    OpenToolRow(tool: $tool) { model.settings.openTools.removeAll { $0.bundleID == tool.bundleID } }
                }
                .onMove { model.settings.openTools.move(fromOffsets: $0, toOffset: $1) }
                if model.settings.openTools.isEmpty {
                    Text(L("还没有打开工具。")).foregroundStyle(.secondary)
                }
            } header: {
                HStack {
                    Text(L("打开工具"))
                    Spacer()
                    Button(L("检测已安装工具")) {
                        model.settings.openTools = OpenToolDetector.detect(adding: model.settings.openTools)
                    }
                    Button(L("添加应用…"), action: addApp)
                }
            } footer: {
                Text(L("终端打开所在文件夹，编辑器打开所选项目。"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(!model.settings.groups.openIn)
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(filePath: "/Applications")
        panel.prompt = L("添加")
        guard panel.runModal() == .OK, let url = panel.url, let tool = OpenToolDetector.tool(forAppAt: url) else { return }
        guard !model.settings.openTools.contains(where: { $0.bundleID == tool.bundleID }) else { return }
        model.settings.openTools.append(tool)
    }
}

private struct OpenToolRow: View {
    @Binding var tool: OpenTool
    let remove: () -> Void

    var body: some View {
        let appURL = OpenToolDetector.appURL(tool.bundleID)
        HStack(spacing: 12) {
            Toggle(isOn: $tool.enabled) { EmptyView() }
                .labelsHidden()
                .accessibilityLabel(tool.name)
            if let appURL {
                FileIcon(path: appURL.path(percentEncoded: false))
            } else {
                RowIcon(symbol: "questionmark.app.dashed", tint: .intentInspect)
            }
            RowLabel(title: tool.name, caption: appURL == nil ? L("“%@”已不在系统中。", tool.name) : nil)
            Spacer()
            Picker(L("角色"), selection: $tool.role) {
                Text(L("编辑器")).tag(OpenToolRole.editor)
                Text(L("终端")).tag(OpenToolRole.terminal)
            }
            .labelsHidden()
            .fixedSize()
            RemoveButton(itemName: tool.name, action: remove)
        }
    }
}
