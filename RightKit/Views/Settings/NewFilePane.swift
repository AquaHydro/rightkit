import RightKitCore
import SwiftUI
import UniformTypeIdentifiers

/// F-010 至 F-016。
struct NewFilePane: View {
    @Environment(AppModel.self) private var model
    @State private var importFailed = false

    var body: some View {
        @Bindable var model = model
        Pane {
            Section {
                Toggle(isOn: $model.settings.openAfterCreate) {
                    RowLabel(title: L("创建后自动打开文件"), caption: L("使用该文件类型的默认应用打开。"),
                             symbol: "arrow.up.forward.app", tint: .intentGo)
                }
                Toggle(isOn: $model.settings.askFileName) {
                    RowLabel(title: L("创建前询问文件名"), symbol: "character.cursor.ibeam", tint: .intentCopy)
                }
            }

            Section {
                ForEach($model.settings.newItems) { $item in
                    HStack(spacing: 8) {
                        Toggle(isOn: $item.enabled) {
                            HStack(spacing: 12) {
                                FileIcon(fileExtension: item.fileExtension)
                                RowLabel(title: item.title,
                                         caption: item.fileExtension.isEmpty ? L("无扩展名") : "." + item.fileExtension,
                                         monospacedCaption: true)
                            }
                        }
                        if case .custom(let template) = item.kind {
                            RemoveButton { remove(template) }
                        }
                    }
                }
                .onMove { model.settings.newItems.move(fromOffsets: $0, toOffset: $1) }
            } header: {
                HStack {
                    Text(L("文件类型"))
                    Spacer()
                    Button(L("添加模板…"), action: addTemplate)
                }
            } footer: {
                HStack {
                    Text(L("拖动可调整菜单中的顺序。"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(L("恢复默认")) { model.settings.resetNewFilePage() }
                }
            }
        }
        .disabled(!model.settings.groups.newFile)
        .alert(L("无法导入模板。"), isPresented: $importFailed) { Button(L("好")) {} }
    }

    private func addTemplate() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.prompt = L("添加")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let name = askTemplateName(default: Naming.removingExtension(url.lastPathComponent)) else { return }
        do {
            let template = try TemplateLibrary.importTemplate(from: url, name: name)
            model.settings.newItems.append(NewItemEntry(kind: .custom(template), enabled: true))
        } catch {
            importFailed = true
        }
    }

    /// 菜单名默认用原文件名。
    private func askTemplateName(default name: String) -> String? {
        let alert = NSAlert()
        alert.messageText = L("添加模板")
        alert.informativeText = L("输入这个模板在菜单中的名称：")
        let field = NSTextField(string: name)
        field.frame = NSRect(x: 0, y: 0, width: 260, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: L("添加"))
        alert.addButton(withTitle: L("取消"))
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let trimmed = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? name : trimmed
    }

    private func remove(_ template: CustomTemplate) {
        model.settings.newItems.removeAll { if case .custom(let t) = $0.kind { t.id == template.id } else { false } }
        TemplateLibrary.remove(template)
    }
}
