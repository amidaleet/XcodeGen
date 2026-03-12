import Foundation
import JSONutils

public struct BuildRule: Equatable {
    public static let scriptCompilerSpec = "com.apple.compilers.proxy.script"
    public static let filePatternFileType = "pattern.proxy"
    public static let runOncePerArchitectureDefault = true

    public enum FileType: Equatable {
        case type(String)
        case pattern(String)

        public var fileType: String {
            switch self {
            case let .type(fileType): fileType
            case .pattern: BuildRule.filePatternFileType
            }
        }

        public var pattern: String? {
            switch self {
            case .type: nil
            case let .pattern(pattern): pattern
            }
        }
    }

    public enum Action: Equatable {
        case compilerSpec(String)
        case script(String)

        public var compilerSpec: String {
            switch self {
            case let .compilerSpec(compilerSpec): compilerSpec
            case .script: BuildRule.scriptCompilerSpec
            }
        }

        public var script: String? {
            switch self {
            case .compilerSpec: nil
            case let .script(script): script
            }
        }
    }

    public var fileType: FileType
    public var action: Action
    public var outputFiles: [String]
    public var outputFilesCompilerFlags: [String]
    public var name: String?
    public var runOncePerArchitecture: Bool

    public init(
        fileType: FileType,
        action: Action,
        name: String? = nil,
        outputFiles: [String] = [],
        outputFilesCompilerFlags: [String] = [],
        runOncePerArchitecture: Bool = runOncePerArchitectureDefault
    ) {
        self.fileType = fileType
        self.action = action
        self.name = name
        self.outputFiles = outputFiles
        self.outputFilesCompilerFlags = outputFilesCompilerFlags
        self.runOncePerArchitecture = runOncePerArchitecture
    }
}

extension BuildRule: JSONObjectConvertible {
    public init(jsonDictionary: JSONDictionary) throws {
        if let fileType: String = jsonDictionary.json(atKeyPath: "fileType") {
            self.fileType = .type(fileType)
        } else {
            fileType = .pattern(try jsonDictionary.jsonStrict(atKeyPath: "filePattern"))
        }

        if let compilerSpec: String = jsonDictionary.json(atKeyPath: "compilerSpec") {
            action = .compilerSpec(compilerSpec)
        } else {
            action = .script(try jsonDictionary.jsonStrict(atKeyPath: "script"))
        }

        outputFiles = jsonDictionary.json(atKeyPath: "outputFiles") ?? []
        outputFilesCompilerFlags = jsonDictionary.json(atKeyPath: "outputFilesCompilerFlags") ?? []
        name = jsonDictionary.json(atKeyPath: "name")
        runOncePerArchitecture = jsonDictionary.json(atKeyPath: "runOncePerArchitecture") ?? BuildRule.runOncePerArchitectureDefault
    }
}

extension BuildRule: JSONEncodable {
    public func toJSONValue() -> Any {
        var dict: [String: Any?] = [
            "outputFiles": outputFiles,
            "outputFilesCompilerFlags": outputFilesCompilerFlags,
            "name": name,
        ]

        switch fileType {
        case let .pattern(string):
            dict["filePattern"] = string
        case let .type(string):
            dict["fileType"] = string
        }

        switch action {
        case let .compilerSpec(string):
            dict["compilerSpec"] = string
        case let .script(string):
            dict["script"] = string
        }

        if runOncePerArchitecture != BuildRule.runOncePerArchitectureDefault {
            dict["runOncePerArchitecture"] = runOncePerArchitecture
        }

        return dict
    }
}
