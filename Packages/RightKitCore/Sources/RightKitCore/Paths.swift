import Foundation

/// 重名编号、文件名与路径规则。只做字符串计算，由调用方提供“是否已被占用”。
public enum Naming {
    /// “未命名.txt” 的第 n 个候选：n 为 1 时原样，其后在最后一个扩展名前加 “ n”。
    public static func candidate(_ name: String, index: Int) -> String {
        guard index > 1 else { return name }
        let ext = (name as NSString).pathExtension
        let base = ext.isEmpty ? name : String(name.dropLast(ext.count + 1))
        return ext.isEmpty ? "\(base) \(index)" : "\(base) \(index).\(ext)"
    }

    public static func unique(_ name: String, isTaken: (String) -> Bool) -> String {
        var index = 1
        while isTaken(candidate(name, index: index)) { index += 1 }
        return candidate(name, index: index)
    }

    /// 新建文件的默认名。
    public static func untitled(fileExtension ext: String) -> String {
        withExtension(L("未命名"), ext)
    }

    public static func withExtension(_ name: String, _ ext: String) -> String {
        ext.isEmpty ? name : "\(name).\(ext)"
    }

    /// F-013：没有以该扩展名结尾时补上。大小写不敏感。
    public static func ensuringExtension(_ name: String, _ ext: String) -> String {
        guard !ext.isEmpty, !name.lowercased().hasSuffix("." + ext.lowercased()) else { return name }
        return "\(name).\(ext)"
    }

    /// 去掉最后一个扩展名；没有扩展名时返回完整文件名（F-043）。
    public static func removingExtension(_ name: String) -> String {
        let stripped = (name as NSString).deletingPathExtension
        return stripped.isEmpty ? name : stripped
    }

    /// F-055 iOS 图标集文件夹名。
    public static func iOSIconFolderName(forImage name: String) -> String {
        "\(removingExtension(name)) iOS"
    }

    /// 能否作为单个文件名使用。
    public static func isValidFileName(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/") && !name.contains("\0")
            && name.utf8.count <= 255
    }
}

public enum PathRules {
    /// F-073 受保护的系统目录，含目录本身。
    public static let protectedRoots = ["/System", "/usr", "/bin", "/sbin", "/Library", "/private/var"]

    public static func isSameOrInside(_ path: String, _ root: String) -> Bool {
        let p = standardized(path), r = standardized(root)
        return p == r || r == "/" || p.hasPrefix(r + "/")
    }

    /// 去掉多余的 `/` 和 `.`。不用 `standardizingPath`，它会把 `/private/var` 改写成 `/var`。
    public static func standardized(_ path: String) -> String {
        "/" + path.split(separator: "/").filter { $0 != "." }.joined(separator: "/")
    }

    /// `resolvedPath` 和 `home` 都应已解析符号链接。
    public static func isProtectedFromDeletion(resolvedPath: String, home: String) -> Bool {
        let p = standardized(resolvedPath)
        if p == "/" || p == standardized(home) { return true }
        return protectedRoots.contains { isSameOrInside(p, $0) }
    }

    /// F-009：不能监视根目录、系统目录，或主目录的上级目录。
    public static func canMonitor(_ path: String, home: String) -> Bool {
        let p = standardized(path)
        let system = protectedRoots + ["/private", "/dev", "/cores", "/Volumes", "/etc", "/var", "/tmp", "/opt", "/Users"]
        if p == "/" || system.contains(where: { p == $0 }) { return false }
        if protectedRoots.contains(where: { isSameOrInside(p, $0) }) { return false }
        let h = standardized(home)
        return !(h != p && isSameOrInside(h, p))
    }

    public static func isInsideAny(_ path: String, of roots: [String]) -> Bool {
        roots.contains { $0 != "/" && isSameOrInside(path, $0) }
    }

    /// Finder 菜单一次构建期间复用标准化后的监视目录。
    struct MonitoringScope {
        private struct Root {
            let path: String
            let childPrefix: String

            init(_ path: String) {
                self.path = path
                childPrefix = path + "/"
            }
        }

        private let roots: [Root]

        init(_ roots: [String]) {
            // 与 isInsideAny 的旧行为一致，仅原始的 "/" 被排除。
            self.roots = roots.filter { $0 != "/" }.map { Root(PathRules.standardized($0)) }
        }

        func contains(_ path: String) -> Bool {
            guard !roots.isEmpty else { return false }
            let path = PathRules.standardized(path)
            return roots.contains { root in
                path == root.path || root.path == "/" || path.hasPrefix(root.childPrefix)
            }
        }
    }

    /// 把文件夹移动到它自己里面（F-032）。
    public static func isMovingIntoItself(source: String, destinationFolder: String) -> Bool {
        isSameOrInside(destinationFolder, source)
    }
}
