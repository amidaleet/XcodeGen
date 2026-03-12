import Foundation
import JSONutils
import PathKit
import Version
import XcodeProj
import Yams

public final class SpecLoader {
    let version: Version

    var project: Project!
    public private(set) var projectDictionary: [String: Any]?

    public init(version: Version) {
        self.version = version
    }

    public func loadProject(path: Path) throws -> Project {
        let spec = try SpecFile(path: path)
        let resolvedDictionary = spec.resolvedDictionary()
        let project = try Project(basePath: spec.basePath, jsonDictionary: resolvedDictionary)

        self.project = project
        projectDictionary = resolvedDictionary

        return project
    }

    public func validateProjectDictionaryWarnings() throws {
        // TODO: ?
    }

    public func generateCacheFile() throws -> CacheFile? {
        guard let projectDictionary = projectDictionary,
              let project = project
        else {
            return nil
        }
        return try CacheFile(
            version: version,
            projectDictionary: projectDictionary,
            project: project
        )
    }
}
