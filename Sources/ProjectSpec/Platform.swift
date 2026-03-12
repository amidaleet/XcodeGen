import Foundation

public enum Platform: String, Hashable, CaseIterable, Sendable {
    case auto
    case iOS
    case tvOS
    case macOS
    case watchOS
    case visionOS
}
