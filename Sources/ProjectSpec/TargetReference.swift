import Foundation
import JSONutils

public struct TargetReference: Hashable, Sendable {
    public var name: String
    public var location: Location

    public enum Location: Hashable, Sendable {
        case local
        case project(String)
    }

    public init(name: String, location: Location) {
        self.name = name
        self.location = location
    }
}

extension TargetReference {
    public init(_ string: String) throws {
        let paths = string.split(separator: "/")
        switch paths.count {
        case 2:
            location = .project(String(paths[0]))
            name = String(paths[1])
        case 1:
            location = .local
            name = String(paths[0])
        default:
            throw SpecParsingError.invalidTargetReference(string)
        }
    }

    public static func local(_ name: String) -> TargetReference {
        TargetReference(name: name, location: .local)
    }
}

extension TargetReference: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        try! self.init(value)
    }
}

extension TargetReference: CustomStringConvertible {
    public var reference: String {
        switch location {
        case .local: name
        case let .project(root):
            "\(root)/\(name)"
        }
    }

    public var description: String {
        reference
    }
}
