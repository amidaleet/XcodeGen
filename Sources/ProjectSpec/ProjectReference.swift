import Foundation
import JSONutils

public struct ProjectReference: Hashable, Sendable {
    public var name: String
    public var path: String

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

extension ProjectReference: PathContainer {
    /// Only dict version path properties
    static var pathProperties: [PathProperty] {
        [
            .dictionary([
                .string("path"),
            ]),
        ]
    }
}

extension ProjectReference: NamedJSONConvertible {
    public init(name: String, json: Any) throws {
        if let jsonDictionary = json as? JSONDictionary {
            try self.init(name: name, jsonDictionary: jsonDictionary)
        } else if let pathString = json as? String {
            self = ProjectReference(name: name, path: pathString)
        } else {
            throw JSONUtilsError.fileDeserializationFailed
        }
    }

    public init(name: String, jsonDictionary: JSONDictionary) throws {
        self.name = name
        self.path = try jsonDictionary.jsonStrict(atKeyPath: "path")
    }
}

extension ProjectReference: JSONEncodable {
    public func toJSONValue() -> Any {
        [
            "path": path,
        ]
    }
}
