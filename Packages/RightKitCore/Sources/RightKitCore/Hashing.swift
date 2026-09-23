import CryptoKit
import Foundation

/// F-049 四个算法的结果，顺序固定。
public struct FileHashes: Equatable, Sendable {
    public enum Algorithm: String, CaseIterable, Sendable {
        case md5 = "MD5", sha1 = "SHA-1", sha256 = "SHA-256", sha512 = "SHA-512"
    }

    public var md5: String
    public var sha1: String
    public var sha256: String
    public var sha512: String

    public func value(_ algorithm: Algorithm) -> String {
        switch algorithm {
        case .md5: md5
        case .sha1: sha1
        case .sha256: sha256
        case .sha512: sha512
        }
    }
}

/// 流式计算四个哈希，调用方按块喂数据。
public struct MultiHasher: Sendable {
    private var md5 = Insecure.MD5()
    private var sha1 = Insecure.SHA1()
    private var sha256 = SHA256()
    private var sha512 = SHA512()

    public init() {}

    public mutating func update(_ data: some DataProtocol) {
        md5.update(data: data)
        sha1.update(data: data)
        sha256.update(data: data)
        sha512.update(data: data)
    }

    public func finalize() -> FileHashes {
        func hex(_ digest: some Digest) -> String { digest.map { String(format: "%02x", $0) }.joined() }
        return FileHashes(md5: hex(md5.finalize()), sha1: hex(sha1.finalize()),
                          sha256: hex(sha256.finalize()), sha512: hex(sha512.finalize()))
    }
}
