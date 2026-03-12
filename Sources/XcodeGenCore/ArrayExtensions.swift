import Foundation
import ToolsCore

extension Array {
    public func parallelMap<T>(transform: @Sendable (Element) -> T) -> [T] {
        var result = ContiguousArray<T?>(repeating: nil, count: count)
        return result.withUnsafeMutableBufferPointer { buffer in
            let selfBox = UncheckedSendable(self)
            let bufferBox = UncheckedSendable(buffer)
            DispatchQueue.concurrentPerform(iterations: buffer.count) { idx in
                bufferBox.subject[idx] = transform(selfBox.subject[idx])
            }
            return buffer.map { $0! }
        }
    }
}

extension Array where Element == [String: Any?] {
    public func removingEmptyArraysDictionariesAndNils() -> [[String: Any]] {
        map { $0.removingEmptyArraysDictionariesAndNils() }
    }
}

/// Holds a sorted array, created from specified sequence
/// This structure is needed for the cases, when some part of application requires array to be sorted, but don't trust any inputs :)
public struct SortedArray<T: Comparable> {
    public let value: [T]
    public init<S: Sequence>(_ value: S) where S.Element == T {
        self.value = value.sorted()
    }
}

extension SortedArray {
    /// Returns the first index in which an element of the collection satisfies the given predicate.
    /// The collection assumed to be sorted. If collection is not have sorted values the result is undefined.
    ///
    /// The idea is to get first index of a function for which the given predicate evaluates to true.
    ///
    ///       let values = [1,2,3,4,5]
    ///       let idx = values.firstIndexAssumingSorted(where: { $0 > 3 })
    ///
    ///       // false, false, false, true, true
    ///       //                      ^
    ///       // therefore idx == 3
    ///
    /// - Parameter predicate: A closure that takes an element as its argument
    ///   and returns a Boolean value that indicates whether the passed element
    ///   represents a match.
    ///
    /// - Returns: The index of the first element for which `predicate` returns
    ///   `true`. If no elements in the collection satisfy the given predicate,
    ///   returns `nil`.
    ///
    /// - Complexity: O(log(*n*)), where *n* is the length of the collection.
    @inlinable
    public func firstIndex(where predicate: (T) throws -> Bool) rethrows -> Int? {
        // Predicate should divide a collection to two pairs of values
        // "bad" values for which predicate returns `false``
        // "good" values for which predicate return `true`
        // false false false false false true true true
        //                               ^
        // The idea is to get _first_ index which for which the predicate returns `true`
        let lastIndex = value.count

        // The index that represents where bad values start
        var badIndex = -1

        // The index that represents where good values start
        var goodIndex = lastIndex
        var midIndex = (badIndex + goodIndex) / 2

        while badIndex + 1 < goodIndex {
            if try predicate(value[midIndex]) {
                goodIndex = midIndex
            } else {
                badIndex = midIndex
            }
            midIndex = (badIndex + goodIndex) / 2
        }

        // We're out of bounds, no good items in array
        if midIndex == lastIndex || goodIndex == lastIndex {
            return nil
        }
        return goodIndex
    }
}
