import Foundation
import Security

/// 从自身签名读取团队标识，拼出校验对方进程的签名要求（technical.md 通信）。
public enum CodeSigning {
    public static func ownTeamIdentifier() -> String? {
        var code: SecCode?
        var staticCode: SecStaticCode?
        var info: CFDictionary?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code,
              SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode,
              SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess
        else { return nil }
        return (info as? [String: Any])?[kSecCodeInfoTeamIdentifier as String] as? String
    }

    /// 同一团队、给定签名标识之一。拿不到团队标识时返回 nil，调用方应拒绝连接。
    /// 商店版由 Apple 重签，叶证书主题里没有团队标识，改认 Mac App Store 签名标记（与 Apple 生成的指定要求一致）。
    public static func requirement(identifiers: [String], team: String? = ownTeamIdentifier()) -> String? {
        guard let team, !identifiers.isEmpty else { return nil }
        let ids = identifiers.map { "identifier \"\($0)\"" }.joined(separator: " or ")
        return "anchor apple generic and (\(ids)) and (certificate leaf[field.1.2.840.113635.100.6.1.9] or certificate leaf[subject.OU] = \"\(team)\")"
    }

    /// 读取某个进程的签名标识。只用于区分已通过签名要求的来者是谁。
    public static func identifier(ofProcess pid: pid_t) -> String? {
        var code: SecCode?
        var staticCode: SecStaticCode?
        var info: CFDictionary?
        let attributes = [kSecGuestAttributePid: pid] as CFDictionary
        guard SecCodeCopyGuestWithAttributes(nil, attributes, [], &code) == errSecSuccess, let code,
              SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode,
              SecCodeCopySigningInformation(staticCode, [], &info) == errSecSuccess
        else { return nil }
        return (info as? [String: Any])?[kSecCodeInfoIdentifier as String] as? String
    }
}
