import Foundation
import JSONutils
import Version
import XcodeProj

public struct Target: ProjectTarget, @unchecked Sendable {
    public var name: String
    public var type: PBXProductType
    public var platform: Platform
    public var supportedDestinations: [SupportedDestination]?
    public var settings: Settings
    public var sources: [TargetSource]
    public var dependencies: [Dependency]
    public var info: Plist?
    public var entitlements: Plist?
    public var transitivelyLinkDependencies: Bool?
    public var directlyEmbedCarthageDependencies: Bool?
    public var requiresObjCLinking: Bool?
    public var preBuildScripts: [BuildScript]
    public var buildToolPlugins: [BuildToolPlugin]
    public var postCompileScripts: [BuildScript]
    public var postBuildScripts: [BuildScript]
    public var buildRules: [BuildRule]
    public var configFiles: [String: String]
    public var scheme: TargetScheme?
    public var deploymentTarget: Version?
    public var attributes: [String: ProjectAttribute]
    public var productName: String
    public var onlyCopyFilesOnInstall: Bool
    public var putResourcesBeforeSourcesBuildPhase: Bool

    public var filename: String {
        var filename = productName
        if let fileExtension = type.fileExtension {
            filename += ".\(fileExtension)"
        }
        if type == .staticLibrary {
            filename = "lib\(filename)"
        }
        return filename
    }

    public init(
        name: String,
        type: PBXProductType,
        platform: Platform,
        supportedDestinations: [SupportedDestination]? = nil,
        productName: String? = nil,
        deploymentTarget: Version? = nil,
        settings: Settings = .empty,
        configFiles: [String: String] = [:],
        sources: [TargetSource] = [],
        dependencies: [Dependency] = [],
        info: Plist? = nil,
        entitlements: Plist? = nil,
        transitivelyLinkDependencies: Bool? = nil,
        directlyEmbedCarthageDependencies: Bool? = nil,
        requiresObjCLinking: Bool? = nil,
        preBuildScripts: [BuildScript] = [],
        buildToolPlugins: [BuildToolPlugin] = [],
        postCompileScripts: [BuildScript] = [],
        postBuildScripts: [BuildScript] = [],
        buildRules: [BuildRule] = [],
        scheme: TargetScheme? = nil,
        attributes: [String: ProjectAttribute] = [:],
        onlyCopyFilesOnInstall: Bool = false,
        putResourcesBeforeSourcesBuildPhase: Bool = false
    ) {
        self.name = name
        self.type = type
        self.platform = platform
        self.supportedDestinations = supportedDestinations
        self.deploymentTarget = deploymentTarget
        self.productName = productName ?? name
        self.settings = settings
        self.configFiles = configFiles
        self.sources = sources
        self.dependencies = dependencies
        self.info = info
        self.entitlements = entitlements
        self.transitivelyLinkDependencies = transitivelyLinkDependencies
        self.directlyEmbedCarthageDependencies = directlyEmbedCarthageDependencies
        self.requiresObjCLinking = requiresObjCLinking
        self.preBuildScripts = preBuildScripts
        self.buildToolPlugins = buildToolPlugins
        self.postCompileScripts = postCompileScripts
        self.postBuildScripts = postBuildScripts
        self.buildRules = buildRules
        self.scheme = scheme
        self.attributes = attributes
        self.onlyCopyFilesOnInstall = onlyCopyFilesOnInstall
        self.putResourcesBeforeSourcesBuildPhase = putResourcesBeforeSourcesBuildPhase
    }
}

extension Target: CustomStringConvertible {
    public var description: String {
        "\(name): \(platform.rawValue) \(type)"
    }
}

extension Target: PathContainer {
    static var pathProperties: [PathProperty] {
        [
            .dictionary([
                .string("sources"),
                .object("sources", TargetSource.pathProperties),
                .string("configFiles"),
                .object("dependencies", Dependency.pathProperties),
                .object("info", Plist.pathProperties),
                .object("entitlements", Plist.pathProperties),
                .object("preBuildScripts", BuildScript.pathProperties),
                .object("prebuildScripts", BuildScript.pathProperties),
                .object("postCompileScripts", BuildScript.pathProperties),
                .object("postBuildScripts", BuildScript.pathProperties),
                .object("scheme", TargetScheme.pathProperties),
            ]),
        ]
    }
}

extension Target {
    static func resolveMultiplatformTargets(_ jsonDictionary: inout JSONDictionary) {
        guard let targetsDictionary: [String: JSONDictionary] = jsonDictionary["targets"] as? [String: JSONDictionary] else {
            return
        }

        let targetsToSplit: [String: [String]] = targetsDictionary.reduce(into: [:]) { result, target in
            guard let platforms = target.value["platform"] as? [String] else { return }
            result[target.key] = platforms
        }
        guard !targetsToSplit.isEmpty else {
            return
        }

        var resolvedTargets: [String: JSONDictionary] = targetsDictionary
        resolvedTargets.reserveCapacity(resolvedTargets.count + targetsToSplit.reduce(into: 0) { $0 += $1.value.count })

        for (targetName, platforms) in targetsToSplit {
            resolvedTargets.removeValue(forKey: targetName)
            for platform in platforms {
                var platformTarget = targetsDictionary[targetName]!

                /// This value is set to help us to check, in Target init, that there are no conflicts in the definition of the platforms. We want to ensure that the user didn't define, at the same time,
                /// the new Xcode 14 supported destinations and the XcodeGen generation of Multiple Platform Targets (when you define the platform field as an array).
                platformTarget["isMultiPlatformTarget"] = true

                platformTarget = platformTarget.expandVariables(["platform": platform])

                platformTarget["platform"] = platform
                let platformSuffix = platformTarget["platformSuffix"] as? String ?? "_\(platform)"
                let platformPrefix = platformTarget["platformPrefix"] as? String ?? ""
                let newTargetName = platformPrefix + targetName + platformSuffix

                var settings = platformTarget["settings"] as? JSONDictionary ?? [:]
                if settings["configs"] != nil || settings["groups"] != nil || settings["base"] != nil {
                    var base = settings["base"] as? JSONDictionary ?? [:]
                    if base["PRODUCT_NAME"] == nil {
                        base["PRODUCT_NAME"] = targetName
                    }
                    settings["base"] = base
                } else {
                    if settings["PRODUCT_NAME"] == nil {
                        settings["PRODUCT_NAME"] = targetName
                    }
                }
                platformTarget["productName"] = targetName
                platformTarget["settings"] = settings
                if let deploymentTargets = platformTarget["deploymentTarget"] as? [String: Any] {
                    platformTarget["deploymentTarget"] = deploymentTargets[platform]
                }
                resolvedTargets[newTargetName] = platformTarget
            }
        }

        jsonDictionary["targets"] = resolvedTargets
    }
}

extension Target: Equatable {
    public static func == (lhs: Target, rhs: Target) -> Bool {
        lhs.name == rhs.name &&
            lhs.type == rhs.type &&
            lhs.platform == rhs.platform &&
            lhs.deploymentTarget == rhs.deploymentTarget &&
            lhs.transitivelyLinkDependencies == rhs.transitivelyLinkDependencies &&
            lhs.requiresObjCLinking == rhs.requiresObjCLinking &&
            lhs.directlyEmbedCarthageDependencies == rhs.directlyEmbedCarthageDependencies &&
            lhs.settings == rhs.settings &&
            lhs.configFiles == rhs.configFiles &&
            lhs.sources == rhs.sources &&
            lhs.info == rhs.info &&
            lhs.entitlements == rhs.entitlements &&
            lhs.dependencies == rhs.dependencies &&
            lhs.preBuildScripts == rhs.preBuildScripts &&
            lhs.buildToolPlugins == rhs.buildToolPlugins &&
            lhs.postCompileScripts == rhs.postCompileScripts &&
            lhs.postBuildScripts == rhs.postBuildScripts &&
            lhs.buildRules == rhs.buildRules &&
            lhs.scheme == rhs.scheme &&
            NSDictionary(dictionary: lhs.attributes).isEqual(to: rhs.attributes)
    }
}

extension Target: NamedJSONDictionaryConvertible {
    public init(name: String, jsonDictionary: JSONDictionary) throws {
        let resolvedName: String = jsonDictionary["name"] as? String ?? name
        self.name = resolvedName
        productName = jsonDictionary["productName"] as? String ?? resolvedName

        let typeString: String = jsonDictionary["type"] as? String ?? ""
        if let type = PBXProductType(string: typeString) {
            self.type = type
        } else {
            throw SpecParsingError.unknownTargetType(typeString)
        }

        if let supportedDestinations: [SupportedDestination] = jsonDictionary.json(atKeyPath: "supportedDestinations") {
            self.supportedDestinations = supportedDestinations
        }

        let isResolved = jsonDictionary["isMultiPlatformTarget"] as? Bool ?? false
        if isResolved, supportedDestinations != nil {
            throw SpecParsingError.invalidTargetPlatformAsArray
        }

        var platformString: String = jsonDictionary["platform"] as? String ?? ""
        // platform defaults to 'auto' if it is empty and we are using supported destinations
        if supportedDestinations != nil, platformString.isEmpty {
            platformString = Platform.auto.rawValue
        }
        // we add 'iOS' in supported destinations if it contains only 'macCatalyst'
        if supportedDestinations?.contains(.macCatalyst) == true,
           supportedDestinations?.contains(.iOS) == false {
            supportedDestinations?.append(.iOS)
        }

        if let platform = Platform(rawValue: platformString) {
            self.platform = platform
        } else {
            throw SpecParsingError.unknownTargetPlatform(platformString)
        }

        if let string: String = jsonDictionary["deploymentTarget"] as? String {
            deploymentTarget = try Version.parse(string)
        } else if let double: Double = jsonDictionary["deploymentTarget"] as? Double {
            deploymentTarget = try Version.parse(String(double))
        } else {
            deploymentTarget = nil
        }

        settings = try BuildSettingsParser(jsonDictionary: jsonDictionary).parse()
        configFiles = jsonDictionary["configFiles"] as? [String: String] ?? [:]
        if let source: String = jsonDictionary["sources"] as? String {
            sources = [TargetSource(path: source)]
        } else if let array = jsonDictionary["sources"] as? [Any] {
            sources = try array.compactMap { source in
                if let string = source as? String {
                    TargetSource(path: string)
                } else if let dictionary = source as? [String: Any] {
                    try TargetSource(jsonDictionary: dictionary)
                } else {
                    nil
                }
            }
        } else {
            sources = []
        }
        if jsonDictionary["dependencies"].isNone {
            dependencies = []
        } else {
            let dependencies: [Dependency] = try jsonDictionary.jsonStrict(atKeyPath: "dependencies", invalidItemBehaviour: .fail)
            self.dependencies = dependencies.filter { [platform] dependency -> Bool in
                // If unspecified, all platforms are supported
                guard let platforms = dependency.platforms else { return true }
                return platforms.contains(platform)
            }
        }

        if jsonDictionary["buildToolPlugins"].isNone {
            buildToolPlugins = []
        } else {
            self.buildToolPlugins = try jsonDictionary.jsonStrict(atKeyPath: "buildToolPlugins", invalidItemBehaviour: .fail)
        }

        if jsonDictionary["info"].isSome {
            info = try jsonDictionary.jsonStrict(atKeyPath: "info") as Plist
        }
        if jsonDictionary["entitlements"].isSome {
            entitlements = try jsonDictionary.jsonStrict(atKeyPath: "entitlements") as Plist
        }

        transitivelyLinkDependencies = jsonDictionary.json(atKeyPath: "transitivelyLinkDependencies")
        directlyEmbedCarthageDependencies = jsonDictionary.json(atKeyPath: "directlyEmbedCarthageDependencies")
        requiresObjCLinking = jsonDictionary.json(atKeyPath: "requiresObjCLinking")

        preBuildScripts = jsonDictionary.json(atKeyPath: "preBuildScripts") ?? jsonDictionary.json(atKeyPath: "prebuildScripts") ?? []
        postCompileScripts = jsonDictionary.json(atKeyPath: "postCompileScripts") ?? []
        postBuildScripts = jsonDictionary.json(atKeyPath: "postBuildScripts") ?? jsonDictionary.json(atKeyPath: "postbuildScripts") ?? []
        buildRules = jsonDictionary.json(atKeyPath: "buildRules") ?? []
        scheme = jsonDictionary.json(atKeyPath: "scheme")
        attributes = try jsonDictionary.json(atKeyPath: "attributes")?.asProjectAttributes() ?? [:]
        onlyCopyFilesOnInstall = jsonDictionary.json(atKeyPath: "onlyCopyFilesOnInstall") ?? false
        putResourcesBeforeSourcesBuildPhase = jsonDictionary.json(atKeyPath: "putResourcesBeforeSourcesBuildPhase") ?? false
    }
}

extension Target: JSONEncodable {
    public func toJSONValue() -> Any {
        var dict: [String: Any?] = [
            "type": type.name,
            "platform": platform.rawValue,
            "supportedDestinations": supportedDestinations?.map(\.rawValue),
            "settings": settings.toJSONValue(),
            "configFiles": configFiles,
            "attributes": attributes,
            "sources": sources.map { $0.toJSONValue() },
            "dependencies": dependencies.map { $0.toJSONValue() },
            "postCompileScripts": postCompileScripts.map { $0.toJSONValue() },
            "prebuildScripts": preBuildScripts.map { $0.toJSONValue() },
            "buildToolPlugins": buildToolPlugins.map { $0.toJSONValue() },
            "postbuildScripts": postBuildScripts.map { $0.toJSONValue() },
            "buildRules": buildRules.map { $0.toJSONValue() },
            "deploymentTarget": deploymentTarget?.deploymentTarget,
            "info": info?.toJSONValue(),
            "entitlements": entitlements?.toJSONValue(),
            "transitivelyLinkDependencies": transitivelyLinkDependencies,
            "directlyEmbedCarthageDependencies": directlyEmbedCarthageDependencies,
            "requiresObjCLinking": requiresObjCLinking,
            "scheme": scheme?.toJSONValue(),
        ]

        if productName != name {
            dict["productName"] = productName
        }

        if onlyCopyFilesOnInstall {
            dict["onlyCopyFilesOnInstall"] = true
        }

        if putResourcesBeforeSourcesBuildPhase {
            dict["putResourcesBeforeSourcesBuildPhase"] = true
        }

        return dict
    }
}
