import Foundation
import JSONutils
import Version
import XcodeProj

public enum SwiftPackage: Equatable {
    public typealias VersionRequirement = XCRemoteSwiftPackageReference.VersionRequirement

    static let githubPrefix = "https://github.com/"

    case remote(url: String, versionRequirement: VersionRequirement)
    case local(path: String, group: String?, excludeFromProject: Bool = false)

    public var isLocal: Bool {
        if case .local = self {
            return true
        }
        return false
    }
}

extension SwiftPackage: JSONObjectConvertible {
    public init(jsonDictionary: JSONDictionary) throws {
        if let path: String = jsonDictionary.json(atKeyPath: "path") {
            let customLocation: String? = jsonDictionary.json(atKeyPath: "group")
            let excludeFromProject: Bool = jsonDictionary.json(atKeyPath: "excludeFromProject") ?? false
            self = .local(path: path, group: customLocation, excludeFromProject: excludeFromProject)
        } else {
            let versionRequirement: VersionRequirement = try VersionRequirement(jsonDictionary: jsonDictionary)
            try Self.validateVersion(versionRequirement: versionRequirement)
            let url: String
            if jsonDictionary["github"] != nil {
                let github: String = try jsonDictionary.jsonStrict(atKeyPath: "github")
                url = "\(Self.githubPrefix)\(github)"
            } else {
                url = try jsonDictionary.jsonStrict(atKeyPath: "url")
            }
            self = .remote(url: url, versionRequirement: versionRequirement)
        }
    }

    private static func validateVersion(versionRequirement: VersionRequirement) throws {
        switch versionRequirement {
        case let .upToNextMajorVersion(version):
            try _ = Version.parse(version)

        case let .upToNextMinorVersion(version):
            try _ = Version.parse(version)

        case let .range(from, to):
            try _ = Version.parse(from)
            try _ = Version.parse(to)

        case let .exact(version):
            try _ = Version.parse(version)

        default:
            break
        }
    }
}

extension SwiftPackage: JSONEncodable {
    public func toJSONValue() -> Any {
        var dictionary: JSONDictionary = [:]
        switch self {
        case let .remote(url, versionRequirement):
            if url.hasPrefix(Self.githubPrefix) {
                dictionary["github"] = url.replacingOccurrences(of: Self.githubPrefix, with: "")
            } else {
                dictionary["url"] = url
            }

            switch versionRequirement {
            case let .upToNextMajorVersion(version):
                dictionary["majorVersion"] = version
            case let .upToNextMinorVersion(version):
                dictionary["minorVersion"] = version
            case let .range(from, to):
                dictionary["minVersion"] = from
                dictionary["maxVersion"] = to
            case let .exact(version):
                dictionary["exactVersion"] = version
            case let .branch(branch):
                dictionary["branch"] = branch
            case let .revision(revision):
                dictionary["revision"] = revision
            }
            return dictionary
        case let .local(path, group, excludeFromProject):
            dictionary["path"] = path
            dictionary["group"] = group
            dictionary["excludeFromProject"] = excludeFromProject
        }

        return dictionary
    }
}

extension SwiftPackage.VersionRequirement: @retroactive JSONObjectConvertible {
    public init(jsonDictionary: JSONDictionary) throws {
        func json(atKeyPath keyPath: String) -> String? {
            if jsonDictionary[keyPath] != nil {
                do {
                    let value: String = try jsonDictionary.jsonStrict(atKeyPath: KeyPath(rawValue: keyPath))
                    return value
                } catch {
                    do {
                        let value: Double = try jsonDictionary.jsonStrict(atKeyPath: KeyPath(rawValue: keyPath))
                        return String(value)
                    } catch {
                        return nil
                    }
                }
            }
            return nil
        }

        if let exactVersion = json(atKeyPath: "exactVersion") {
            self = .exact(exactVersion)
        } else if let version = json(atKeyPath: "version") {
            self = .exact(version)
        } else if let revision = json(atKeyPath: "revision") {
            self = .revision(revision)
        } else if let branch = json(atKeyPath: "branch") {
            self = .branch(branch)
        } else if let minVersion = json(atKeyPath: "minVersion"), let maxVersion = json(atKeyPath: "maxVersion") {
            self = .range(from: minVersion, to: maxVersion)
        } else if let minorVersion = json(atKeyPath: "minorVersion") {
            self = .upToNextMinorVersion(minorVersion)
        } else if let majorVersion = json(atKeyPath: "majorVersion") {
            self = .upToNextMajorVersion(majorVersion)
        } else if let from = json(atKeyPath: "from") {
            self = .upToNextMajorVersion(from)
        } else {
            throw SpecParsingError.unknownPackageRequirement(jsonDictionary)
        }
    }
}

extension SwiftPackage: PathContainer {
    static var pathProperties: [PathProperty] {
        [
            .dictionary([
                .string("path"),
            ]),
        ]
    }
}
