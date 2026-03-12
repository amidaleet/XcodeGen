//
//  File.swift
//
//
//  Created by Yonas Kolb on 1/5/20.
//

import Foundation
import JSONutils
import XcodeProj

public enum BuildPhaseSpec: Hashable, Sendable {
    case sources
    case headers
    case resources
    case copyFiles(CopyFilesSettings)
    case none
    // Not currently exposed as selectable options, but used internally
    case frameworks
    case runScript
    case carbonResources

    public struct CopyFilesSettings: Hashable, Sendable {
        public static let xpcServices = CopyFilesSettings(
            destination: .productsDirectory,
            subpath: "$(CONTENTS_FOLDER_PATH)/XPCServices",
            phaseOrder: .postCompile
        )

        public static let plugins = CopyFilesSettings(
            destination: .plugins,
            subpath: "$(CONTENTS_FOLDER_PATH)/PlugIns",
            phaseOrder: .postCompile
        )

        public enum Destination: String, Sendable {
            case absolutePath
            case productsDirectory
            case wrapper
            case executables
            case resources
            case javaResources
            case frameworks
            case sharedFrameworks
            case sharedSupport
            case plugins

            public var destination: PBXCopyFilesBuildPhase.SubFolder? {
                switch self {
                case .absolutePath: .absolutePath
                case .productsDirectory: .productsDirectory
                case .wrapper: .wrapper
                case .executables: .executables
                case .resources: .resources
                case .javaResources: .javaResources
                case .frameworks: .frameworks
                case .sharedFrameworks: .sharedFrameworks
                case .sharedSupport: .sharedSupport
                case .plugins: .plugins
                }
            }
        }

        public enum PhaseOrder: String, Sendable {
            /// Run before the Compile Sources phase
            case preCompile
            /// Run after the Compile Sources and post-compile Run Script phases
            case postCompile
        }

        public var destination: Destination
        public var subpath: String
        public var phaseOrder: PhaseOrder

        public init(
            destination: Destination,
            subpath: String,
            phaseOrder: PhaseOrder
        ) {
            self.destination = destination
            self.subpath = subpath
            self.phaseOrder = phaseOrder
        }
    }

    public var buildPhase: BuildPhase? {
        switch self {
        case .sources: .sources
        case .headers: .headers
        case .resources: .resources
        case .copyFiles: .copyFiles
        case .frameworks: .frameworks
        case .runScript: .runScript
        case .carbonResources: .carbonResources
        case .none: nil
        }
    }
}

extension BuildPhaseSpec {
    public init(string: String) throws {
        switch string {
        case "sources": self = .sources
        case "headers": self = .headers
        case "resources": self = .resources
        case "copyFiles":
            throw SpecParsingError.invalidSourceBuildPhase("copyFiles must specify a \"destination\" and optional \"subpath\"")
        case "none": self = .none
        default:
            throw SpecParsingError.invalidSourceBuildPhase(string.quoted)
        }
    }
}

extension BuildPhaseSpec: JSONObjectConvertible {
    public init(jsonDictionary: JSONDictionary) throws {
        self = .copyFiles(try jsonDictionary.jsonStrict(atKeyPath: "copyFiles"))
    }
}

extension BuildPhaseSpec: JSONEncodable {
    public func toJSONValue() -> Any {
        switch self {
        case .sources: "sources"
        case .headers: "headers"
        case .resources: "resources"
        case let .copyFiles(files): ["copyFiles": files.toJSONValue()]
        case .none: "none"
        case .frameworks: fatalError("invalid build phase")
        case .runScript: fatalError("invalid build phase")
        case .carbonResources: fatalError("invalid build phase")
        }
    }
}

extension BuildPhaseSpec.CopyFilesSettings: JSONObjectConvertible {
    public init(jsonDictionary: JSONDictionary) throws {
        destination = try jsonDictionary.jsonStrict(atKeyPath: "destination")
        subpath = jsonDictionary.json(atKeyPath: "subpath") ?? ""
        phaseOrder = .postCompile
    }
}

extension BuildPhaseSpec.CopyFilesSettings: JSONEncodable {
    public func toJSONValue() -> Any {
        [
            "destination": destination.rawValue,
            "subpath": subpath,
        ]
    }
}
