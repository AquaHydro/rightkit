import RightKitCore
import SwiftUI
import UniformTypeIdentifiers

enum SettingsTab: String, CaseIterable {
    case general, newFile, openIn, folders, toolbox

    var title: String {
        switch self {
        case .general: L("通用")
        case .newFile: L("新建文件")
        case .openIn: L("打开方式")
        case .folders: L("目录")
        case .toolbox: L("工具箱")
        }
    }
}

/// DESIGN.md 设置窗口：可缩放的普通窗口，标题栏中间是分段标签，关于在右上角。
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("settingsTab") private var tab = SettingsTab.general
    @State private var showingAbout = false

    var body: some View {
        Group {
            switch tab {
            case .general: GeneralPane()
            case .newFile: NewFilePane()
            case .openIn: OpenInPane()
            case .folders: FoldersPane()
            case .toolbox: ToolboxPane()
            }
        }
        .frame(minWidth: 420, idealWidth: 640, minHeight: 360, idealHeight: 620)
        .navigationTitle("RightKit")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker(L("分栏"), selection: $tab) {
                    ForEach(SettingsTab.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            ToolbarItem(placement: .primaryAction) {
                Button(L("关于"), systemImage: "info.circle") { showingAbout = true }
                    .popover(isPresented: $showingAbout, arrowEdge: .bottom) { AboutPane() }
            }
        }
        // 切换语言后整棵视图用新文案重建。
        .id(model.settings.language)
    }
}

/// 每个分栏共用的外形：分组表单，随窗口缩放，内容超出时滚动。
struct Pane<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        Form { content }
            .formStyle(.grouped)
    }
}

/// 行首的意图色图标块：实色底加白色符号，和系统设置一致；颜色与访达菜单的意图分类一致（docs/design/menu-system.html）。
struct RowIcon: View {
    let symbol: String
    let tint: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(tint.gradient, in: .rect(cornerRadius: 6))
            .accessibilityHidden(true)
    }
}

/// 设置行的标签：图标块、标题、可选说明。放在 Toggle、Picker、LabeledContent 的标签位置。
struct RowLabel: View {
    let title: String
    var caption: String?
    var symbol: String?
    var tint: Color = .accentColor
    var monospacedCaption = false

    var body: some View {
        HStack(spacing: 10) {
            if let symbol { RowIcon(symbol: symbol, tint: tint) }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let caption {
                    Text(caption)
                        .font(monospacedCaption ? .callout.monospaced() : .callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(monospacedCaption ? 1 : nil)
                        .truncationMode(.middle)
                        .fixedSize(horizontal: false, vertical: !monospacedCaption)
                }
            }
        }
    }
}

extension Color {
    /// 意图色，与访达菜单设计系统一致。
    static let intentCreate = Color.green
    static let intentGo = Color.orange
    static let intentCopy = Color.blue
    static let intentSend = Color.cyan
    static let intentInspect = Color.gray
    static let intentLook = Color.purple
    static let intentDanger = Color.red

    /// 品牌炭灰，只用于角色头像的底（DESIGN.md `ink`）。
    static let brandInk = Color(red: 0x2A / 255, green: 0x2B / 255, blue: 0x31 / 255)
}

/// 行首的文件夹、应用或文件类型图标，和访达菜单用同一来源。
struct FileIcon: View {
    let image: NSImage

    init(path: String) { image = NSWorkspace.shared.icon(forFile: path) }
    init(fileExtension: String) { image = NSWorkspace.shared.icon(for: UTType(filenameExtension: fileExtension) ?? .data) }

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
    }
}

/// Riko 圆形头像：图片自带图标底色，外加发丝线，浅色窗口里白色外套也有边界。
struct CharacterAvatar: View {
    let name: String
    let size: CGFloat

    var body: some View {
        Image(name)
            .resizable()
            .frame(width: size, height: size)
            .background(Color.brandInk)
            .clipShape(.circle)
            .overlay(Circle().strokeBorder(.separator))
            .accessibilityHidden(true)
    }
}

/// 列表行末尾的移除按钮。
struct RemoveButton: View {
    let itemName: String
    let action: () -> Void

    private var accessibilityTitle: String { "\(L("移除")) \(itemName)" }

    var body: some View {
        Button(action: action) {
            Image(systemName: "minus.circle")
        }
        .buttonStyle(.borderless)
        .help(accessibilityTitle)
        .accessibilityLabel(accessibilityTitle)
    }
}
