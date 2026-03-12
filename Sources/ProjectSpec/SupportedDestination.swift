import Foundation

public enum SupportedDestination: String, CaseIterable, Sendable {
    case iOS
    case tvOS
    case macOS
    case macCatalyst
    case watchOS
    case visionOS
}

extension SupportedDestination {
    public var string: String {
        switch self {
        case .iOS:
            "ios"
        case .tvOS:
            "tvos"
        case .macOS:
            "macos"
        case .macCatalyst:
            "maccatalyst"
        case .watchOS:
            "watchos"
        case .visionOS:
            "xros"
        }
    }

    // This is used to:
    // 1. Get the first one and apply SettingPresets 'Platforms' and 'Product_Platform' if the platform is 'auto'
    // 2. Sort, loop and merge together SettingPresets 'SupportedDestinations'
    public var priority: Int {
        switch self {
        case .iOS:
            0
        case .tvOS:
            1
        case .watchOS:
            2
        case .visionOS:
            3
        case .macOS:
            4
        case .macCatalyst:
            5
        }
    }
}
