import Foundation
import JSONutils
import PathKit
import XcodeProj

extension PBXProductType {
    init?(string: String) {
        if let type = PBXProductType(rawValue: string) {
            self = type
        } else if let type = PBXProductType(rawValue: "com.apple.product-type.\(string)") {
            self = type
        } else {
            return nil
        }
    }

    public var isFramework: Bool {
        self == .framework || self == .staticFramework
    }

    public var isLibrary: Bool {
        self == .staticLibrary || self == .dynamicLibrary
    }

    public var isExtension: Bool {
        fileExtension == "appex"
    }

    public var isSystemExtension: Bool {
        fileExtension == "dext" || fileExtension == "systemextension"
    }

    public var isApp: Bool {
        fileExtension == "app"
    }

    public var isTest: Bool {
        fileExtension == "xctest"
    }

    public var isExecutable: Bool {
        isApp || isExtension || isSystemExtension || isTest || self == .commandLineTool
    }

    public var name: String {
        rawValue.replacingOccurrences(of: "com.apple.product-type.", with: "")
    }

    public var canSkipCompileSourcesBuildPhase: Bool {
        switch self {
        case .bundle,
             .watch2App,
             .stickerPack,
             .messagesApplication:
            // Bundles, watch apps, sticker packs and simple messages applications without sources should not include a
            // compile sources build phase. Doing so can cause Xcode to produce an error on build.
            true
        default:
            false
        }
    }

    /// Function to determine when a dependendency should be embedded into the target
    public func shouldEmbed(_ dependencyTarget: Target) -> Bool {
        switch dependencyTarget.defaultLinkage {
        case .static:
            // Static dependencies should never embed
            false
        case .dynamic,
             .none:
            if isApp {
                // If target is an app, all dependencies should be embed (unless they're static)
                true
            } else if isTest, [.framework, .bundle].contains(dependencyTarget.type) {
                // If target is test, some dependencies should be embed (depending on their type)
                true
            } else {
                // If none of the above, do not embed the dependency
                false
            }
        }
    }
}

extension Platform {
    public var emoji: String {
        switch self {
        case .auto: "🤖"
        case .iOS: "📱"
        case .watchOS: "⌚️"
        case .tvOS: "📺"
        case .macOS: "🖥"
        case .visionOS: "🕶️"
        }
    }
}

extension ProjectTarget {
    public var shouldExecuteOnLaunch: Bool {
        // This is different from `type.isExecutable`, because we don't want to "run" a test
        type.isApp || type.isExtension || type.isSystemExtension || type == .commandLineTool
    }
}

extension XCScheme.CommandLineArguments {
    // Dictionary is a mapping from argument name and if it is enabled by default
    public convenience init(_ dict: [String: Bool]) {
        let args = dict.map { tuple in
            XCScheme.CommandLineArguments.CommandLineArgument(name: tuple.key, enabled: tuple.value)
        }.sorted { $0.name < $1.name }
        self.init(arguments: args)
    }
}

extension BreakpointExtensionID {
    init(string: String) throws {
        if let id = BreakpointExtensionID(rawValue: "Xcode.Breakpoint.\(string)Breakpoint") {
            self = id
        } else if let id = BreakpointExtensionID(rawValue: string) {
            self = id
        } else {
            throw SpecParsingError.unknownBreakpointType(string)
        }
    }
}

extension BreakpointActionExtensionID {
    init(string: String) throws {
        if let type = BreakpointActionExtensionID(rawValue: "Xcode.BreakpointAction.\(string)") {
            self = type
        } else if let type = BreakpointActionExtensionID(rawValue: string) {
            self = type
        } else {
            throw SpecParsingError.unknownBreakpointActionType(string)
        }
    }
}

// MARK: - Decoding

extension JSONDictionary {
    /// Парсинг в типизированный формат XcodeProj.BuildSettings
    public func asBuildSettings() throws -> BuildSettings {
        try self.reduce(into: BuildSettings()) { result, pair in
            if let setting = pair.value as? BuildSetting {
                result[pair.key] = setting
            } else if let string = pair.value as? String {
                result[pair.key] = .string(string)
            } else if let array = pair.value as? [String] {
                result[pair.key] = .array(array)
            } else if let int = pair.value as? Int {
                result[pair.key] = .string("\(int)")
            } else if let double = pair.value as? Double {
                result[pair.key] = .string("\(double)")
            } else if let bool = pair.value as? Bool {
                result[pair.key] = .string("\(bool)")
            } else {
                throw SpecParsingError.mistypedBuildSetting("Got type: \(type(of: pair.value)), value: \(pair.value)")
            }
        }
    }

    /// Парсинг в типизированный формат [String: XcodeProj.ProjectAttribute]
    public func asProjectAttributes() throws -> [String: ProjectAttribute] {
        try self.reduce(into: [String: ProjectAttribute]()) { result, pair in
            if let attribute = pair.value as? ProjectAttribute {
                result[pair.key] = attribute
            } else if let string = pair.value as? String {
                result[pair.key] = .string(string)
            } else if let array = pair.value as? [String] {
                result[pair.key] = .array(array)
            } else if let int = pair.value as? Int {
                result[pair.key] = .string("\(int)")
            } else if let double = pair.value as? Double {
                result[pair.key] = .string("\(double)")
            } else if let bool = pair.value as? Bool {
                result[pair.key] = .string("\(bool)")
            } else if let dict = pair.value as? [String: JSONDictionary] {
                var nested = [String: [String: ProjectAttribute]]()
                for nestedPair in dict {
                    nested[nestedPair.key] = try nestedPair.value.asProjectAttributes()
                }
                result[pair.key] = .attributeDictionary(nested)
            } else {
                throw SpecParsingError.mistypedProjectAttribute("Got type: \(type(of: pair.value)), value: \(pair.value)")
            }
        }
    }
}

extension BuildSetting {
    public var intValue: Int? {
        self.stringValue.flatMap { Int($0) }
    }

    public var doubleValue: Double? {
        self.stringValue.flatMap { Double($0) }
    }

    /// Интерпретатор строчек YES, NO, true, false как Bool
    ///
    /// - Attention: XcodeProj.boolValue поддерживает только YES или NO
    public var fullBoolValue: Bool? {
        switch stringValue?.lowercased() {
        case "true",
             "yes": return true
        case "false",
             "no": return false
        default: return nil
        }
    }
}

extension ProjectAttribute {
    public var targetValue: PBXObject? {
        switch self {
        case let .targetReference(ref): return ref
        default: return nil
        }
    }
}
