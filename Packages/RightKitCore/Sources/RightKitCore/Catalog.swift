import Foundation
import UniformTypeIdentifiers

/// F-010 内置新建类型，顺序即默认顺序。
public enum BuiltinType: String, Codable, CaseIterable, Sendable {
    case txt, md, rtf, docx, xlsx, pptx, json, xml, html, css, js, sh

    public var enabledByDefault: Bool {
        switch self {
        case .txt, .md, .rtf, .docx, .xlsx, .pptx: true
        default: false
        }
    }

    public var title: String {
        switch self {
        case .txt: L("文本文档")
        case .md: "Markdown"
        case .rtf: L("RTF 文稿")
        case .docx: L("Word 文档")
        case .xlsx: L("Excel 工作簿")
        case .pptx: L("PowerPoint 演示文稿")
        case .json: "JSON"
        case .xml: "XML"
        case .html: "HTML"
        case .css: "CSS"
        case .js: "JavaScript"
        case .sh: L("Shell 脚本")
        }
    }

    /// 文本模板的内容。Office 模板返回 nil，由主程序从资源里复制。
    public var textContent: String? {
        switch self {
        case .txt, .md, .css, .js: ""
        case .rtf: "{\\rtf1\\ansi\\pard\\par}"
        case .json: "{}\n"
        case .xml: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root/>\n"
        case .html: "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<title></title>\n</head>\n<body>\n</body>\n</html>\n"
        case .sh: "#!/bin/zsh\n"
        case .docx, .xlsx, .pptx: nil
        }
    }
}

/// F-040 工具箱命令，顺序即默认顺序。
public enum ToolboxCommand: String, Codable, CaseIterable, Sendable {
    case copyPath, copyName
    case newFolderFromName, aliasToDesktop, airDrop, grantWrite, hash
    case toggleHidden, toggleExtension
    case convertImage, macIconset, iosIconset, setWallpaper, setFolderIcon
    case dissolveFolder, deletePermanently

    /// 菜单分组 1 至 5。
    public var group: Int {
        switch self {
        case .copyPath, .copyName: 1
        case .newFolderFromName, .aliasToDesktop, .airDrop, .grantWrite, .hash: 2
        case .toggleHidden, .toggleExtension: 3
        case .convertImage, .macIconset, .iosIconset, .setWallpaper, .setFolderIcon: 4
        case .dissolveFolder, .deletePermanently: 5
        }
    }

    public var isDangerous: Bool { group == 5 }

    /// 设置列表里的名称。
    public var settingsTitle: String {
        switch self {
        case .copyPath: L("拷贝路径")
        case .copyName: L("拷贝名称")
        case .newFolderFromName: L("根据文件名新建文件夹")
        case .aliasToDesktop: L("发送替身到桌面")
        case .airDrop: L("隔空投送")
        case .grantWrite: L("授予写入权限")
        case .hash: L("文件信息（哈希）")
        case .toggleHidden: L("隐藏或显示所选")
        case .toggleExtension: L("隐藏或显示扩展名")
        case .convertImage: L("转换图片")
        case .macIconset: L("生成 macOS 图标集")
        case .iosIconset: L("生成 iOS 图标集")
        case .setWallpaper: L("设为壁纸")
        case .setFolderIcon: L("设置文件夹图标")
        case .dissolveFolder: L("解散文件夹")
        case .deletePermanently: L("彻底删除")
        }
    }

    public var symbol: String {
        switch self {
        case .copyPath: "link"
        case .copyName: "character.cursor.ibeam"
        case .newFolderFromName: "folder.badge.plus"
        case .aliasToDesktop: "arrowshape.turn.up.right"
        case .airDrop: "dot.radiowaves.left.and.right"
        case .grantWrite: "lock.open"
        case .hash: "number"
        case .toggleHidden: "eye.slash"
        case .toggleExtension: "doc.badge.ellipsis"
        case .convertImage: "photo.on.rectangle"
        case .macIconset: "macwindow"
        case .iosIconset: "iphone"
        case .setWallpaper: "photo"
        case .setFolderIcon: "folder.badge.gearshape"
        case .dissolveFolder: "folder.badge.minus"
        case .deletePermanently: "trash"
        }
    }
}

public extension UTType {
    /// 按扩展名判断，不读磁盘。
    static func forPath(_ path: String) -> UTType? {
        let ext = (path as NSString).pathExtension
        return ext.isEmpty ? nil : UTType(filenameExtension: ext)
    }
}
