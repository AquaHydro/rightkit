import Foundation

/// 各动作失败时的提示和批量汇总（features.md 工具行为）。
public enum Messages {
    public static func failure(for action: CommandAction) -> String {
        switch action {
        case .openSettings: L("无法打开设置。")
        case .newFile: L("无法创建文件。")
        case .openFolder: L("该文件夹已不存在。")
        case .openIn: L("无法打开所选项目。")
        case .paste, .moveTo: L("无法移动项目。")
        case .copyTo: L("无法复制项目。")
        case .cut: L("无法剪切项目。")
        case .copyCurrentPath, .copyPath: L("无法拷贝路径。")
        case .copyName: L("无法拷贝名称。")
        case .newFolderFromName: L("无法创建文件夹。")
        case .aliasToDesktop: L("无法创建替身。")
        case .airDrop: L("这台 Mac 无法使用隔空投送。")
        case .grantWrite: L("无法授予写入权限。")
        case .hash: L("无法读取文件。")
        case .toggleHidden: L("无法更改可见性。")
        case .toggleExtension: L("无法更改扩展名显示状态。")
        case .convertImage: L("无法转换图片。")
        case .macIconset: L("iconutil 生成 ICNS 文件失败。")
        case .iosIconset: L("无法生成图标集。")
        case .setWallpaper: L("无法设置壁纸。")
        case .setFolderIcon: L("无法设置文件夹图标。")
        case .dissolveFolder: L("无法解散文件夹。")
        case .deletePermanently: L("无法彻底删除项目。")
        }
    }

    /// 全部成功或用户取消返回 nil；部分失败返回汇总；全部失败返回该命令自己的句子。
    public static func summary(for action: CommandAction, succeeded: Int, failed: Int, cancelled: Bool = false) -> String? {
        guard failed > 0, !cancelled else { return nil }
        guard succeeded > 0 else { return failure(for: action) }
        switch action {
        case .copyTo, .moveTo, .paste: return L("部分项目无法传输。")
        case .deletePermanently: return L("部分项目无法删除。")
        default: return L("部分项目无法完成。")
        }
    }
}
