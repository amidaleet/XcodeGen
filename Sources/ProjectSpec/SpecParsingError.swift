import Foundation

public enum SpecParsingError: Error, CustomStringConvertible, @unchecked Sendable {
    case unknownTargetType(String)
    case unknownTargetPlatform(String)
    case invalidDependency([String: Any])
    case unknownPackageRequirement([String: Any])
    case invalidSourceBuildPhase(String)
    case invalidTargetReference(String)
    case invalidTargetPlatformAsArray
    case invalidVersion(String)
    case mistypedBuildSetting(String)
    case mistypedProjectAttribute(String)
    case unknownBreakpointType(String)
    case unknownBreakpointScope(String)
    case unknownBreakpointStopOnStyle(String)
    case unknownBreakpointActionType(String)
    case unknownBreakpointActionConveyanceType(String)
    case unknownBreakpointActionSoundName(String)
    case invalidConfigsMappingFormat(keys: Set<String>)

    public var description: String {
        switch self {
        case let .unknownTargetType(type):
            "Unknown Target type: \(type)"
        case let .unknownTargetPlatform(platform):
            "Unknown Target platform: \(platform)"
        case let .invalidDependency(dependency):
            "Unknown Target dependency: \(dependency)"
        case let .invalidSourceBuildPhase(error):
            "Invalid Source Build Phase: \(error)"
        case let .invalidTargetReference(targetReference):
            "Invalid Target Reference Syntax: \(targetReference)"
        case .invalidTargetPlatformAsArray:
            "Invalid Target platform: Array not allowed with supported destinations"
        case let .invalidVersion(version):
            "Invalid version: \(version)"
        case let .mistypedBuildSetting(setting):
            "Invalid value type in BuildSetting dict. " + setting
        case let .mistypedProjectAttribute(setting):
            "Invalid value type in ProjectAttribute dict. " + setting
        case let .unknownPackageRequirement(package):
            "Unknown package requirement: \(package)"
        case let .unknownBreakpointType(type):
            "Unknown Breakpoint type: \(type)"
        case let .unknownBreakpointScope(scope):
            "Unknown Breakpoint scope: \(scope)"
        case let .unknownBreakpointStopOnStyle(stopOnStyle):
            "Unknown Breakpoint stopOnStyle: \(stopOnStyle)"
        case let .unknownBreakpointActionType(type):
            "Unknown Breakpoint Action type: \(type)"
        case let .unknownBreakpointActionConveyanceType(type):
            "Unknown Breakpoint Action conveyance type: \(type)"
        case let .unknownBreakpointActionSoundName(name):
            "Unknown Breakpoint Action sound name: \(name)"
        case let .invalidConfigsMappingFormat(keys):
            "Invalid format: The value for \"\(keys.sorted().joined(separator: ", "))\" in `configs` must be mapping format"
        }
    }
}
