import Foundation
import JSONutils

public protocol JSONEncodable {
    // returns JSONDictionary or JSONArray or JSONRawType or nil
    func toJSONValue() -> Any
}
