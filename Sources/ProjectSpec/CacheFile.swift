import Foundation
import Version
import XcodeGenCore

/// Семантически `HashFile` (название оставили от первоисточника пакета)
///
/// Используется для проверки наличия diff,
/// между ранее созданным .xcproject и свежей моделью (из project.yml и файловой системы)
public struct CacheFile: Equatable {
    public let string: String

    /// Raw format constructor, no validation, no format
    public init(string: String) {
        self.string = string
    }

    public init(version: Version, projectDictionary: [String: Any], project: Project) throws {
        let files = Set(project.allTrackedFiles)
            .map { ((try? $0.relativePath(from: project.basePath)) ?? $0).string }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .joined(separator: "\n")

        let data = try JSONSerialization.data(withJSONObject: projectDictionary, options: [.sortedKeys, .prettyPrinted])
        let spec = String(data: data, encoding: .utf8)!

        string = """
        # XCODEGEN VERSION
        \(version)

        # SPEC
        \(spec)

        # FILES
        \(files)"

        """
    }
}

// MARK: - Helpers

extension String {
    public func toCacheFile() -> CacheFile {
        CacheFile(string: self)
    }
}
