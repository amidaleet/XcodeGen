import Foundation
import JSONutils
import Version

public struct DeploymentTarget: Hashable, Sendable {
    public var iOS: Version?
    public var tvOS: Version?
    public var watchOS: Version?
    public var macOS: Version?
    public var visionOS: Version?

    public init(
        iOS: Version? = nil,
        tvOS: Version? = nil,
        watchOS: Version? = nil,
        macOS: Version? = nil,
        visionOS: Version? = nil
    ) {
        self.iOS = iOS
        self.tvOS = tvOS
        self.watchOS = watchOS
        self.macOS = macOS
        self.visionOS = visionOS
    }

    public func version(for platform: Platform) -> Version? {
        switch platform {
        case .auto: nil
        case .iOS: iOS
        case .tvOS: tvOS
        case .watchOS: watchOS
        case .macOS: macOS
        case .visionOS: visionOS
        }
    }
}

extension Platform {
    public var deploymentTargetSetting: String {
        switch self {
        case .auto: ""
        case .iOS: "IPHONEOS_DEPLOYMENT_TARGET"
        case .tvOS: "TVOS_DEPLOYMENT_TARGET"
        case .watchOS: "WATCHOS_DEPLOYMENT_TARGET"
        case .macOS: "MACOSX_DEPLOYMENT_TARGET"
        case .visionOS: "XROS_DEPLOYMENT_TARGET"
        }
    }

    public var sdkRoot: String {
        switch self {
        case .auto: "auto"
        case .iOS: "iphoneos"
        case .tvOS: "appletvos"
        case .watchOS: "watchos"
        case .macOS: "macosx"
        case .visionOS: "xros"
        }
    }
}

extension Version {
    /// doesn't print patch if 0
    public var deploymentTarget: String {
        "\(major).\(minor)\(patch > 0 ? ".\(patch)" : "")"
    }
}

extension DeploymentTarget: JSONObjectConvertible {
    public init(jsonDictionary: JSONDictionary) throws {
        func parseVersion(_ platform: String) throws -> Version? {
            if let string: String = jsonDictionary.json(atKeyPath: .key(platform)) {
                try Version.parse(string)
            } else if let double: Double = jsonDictionary.json(atKeyPath: .key(platform)) {
                try Version.parse(double)
            } else {
                nil
            }
        }
        iOS = try parseVersion("iOS")
        tvOS = try parseVersion("tvOS")
        watchOS = try parseVersion("watchOS")
        macOS = try parseVersion("macOS")
        visionOS = try parseVersion("visionOS")
    }
}

extension DeploymentTarget: JSONEncodable {
    public func toJSONValue() -> Any {
        [
            "iOS": iOS?.description,
            "tvOS": tvOS?.description,
            "watchOS": watchOS?.description,
            "macOS": macOS?.description,
            "visionOS": visionOS?.description,
        ]
    }
}
