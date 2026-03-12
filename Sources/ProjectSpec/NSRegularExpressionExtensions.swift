import Foundation

extension NSRegularExpression {
    public func isMatch(to string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return self.firstMatch(in: string, options: [], range: range) != nil
    }
}
