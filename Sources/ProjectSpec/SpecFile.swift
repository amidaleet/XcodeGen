import Foundation
import JSONutils
import PathKit
import Yams

/// project.yml or template.yml specification
///
/// - Important: Does 2 jobs.
/// 1) ``init()`` means: read raw specs from file (without final ``jsonDictionary`` merge and path values resolution)
/// 2) ``resolvedDictionary()`` means: merge ``jsonDictionary`` (apply included templates and resolve path values)
struct SpecFile {
    private let source: Source

    var basePath: Path { source.basePath }

    let jsonDictionary: JSONDictionary
    let subSpecs: [SpecFile]

    /// Memberwise initializer for SpecFile
    init(
        filePath: Path,
        basePath: Path = "",
        relativePath: Path = "",
        jsonDictionary: JSONDictionary,
        subSpecs: [SpecFile] = []
    ) {
        let source = Source(
            filePath: filePath,
            basePath: basePath,
            relativePath: relativePath
        )
        self.init(source: source, jsonDictionary: jsonDictionary, subSpecs: subSpecs)
    }

    /// Memberwise initializer for SpecFile
    init(source: Source, jsonDictionary: JSONDictionary, subSpecs: [SpecFile]) {
        self.source = source
        self.jsonDictionary = jsonDictionary
        self.subSpecs = subSpecs
    }
}

// MARK: - Read file

extension SpecFile {
    /// Load a SpecFile for a Project
    /// - Parameters:
    ///   - path: The absolute path to the spec file
    init(path: Path) throws {
        var cache = [Path: SpecFile]()

        self = try Self.loadProjectSpec(
            source: try Source.project(path),
            cachedSpecFiles: &cache
        )
    }

    private static func loadProjectSpec(
        source: Source,
        cachedSpecFiles: inout [Path: SpecFile]
    ) throws -> SpecFile {
        let fullFilePath = source.filePath
        if let specFile = cachedSpecFiles[fullFilePath] {
            return specFile
        }

        let jsonDictionary = try Self.loadDictionary(fullFilePath)

        let subSpecs: [SpecFile] = try Include.parseFromSpec(jsonDictionary)
            .filter(\.enable)
            .map { include in
                try Self.loadProjectSpec(
                    source: source.include(include),
                    cachedSpecFiles: &cachedSpecFiles
                )
            }

        let specFile = SpecFile(
            source: source,
            jsonDictionary: jsonDictionary,
            subSpecs: subSpecs
        )
        cachedSpecFiles[fullFilePath] = specFile

        return specFile
    }

    private static func loadDictionary(_ path: Path) throws -> JSONDictionary {
        if path.extension?.lowercased() == "json" {
            let data: Data = try path.read()
            let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            guard let jsonDictionary = jsonData as? [String: Any] else {
                fatalError("Invalid JSON at path \(path)")
            }
            return jsonDictionary
        } else {
            return try loadYamlDictionary(path: path)
        }
    }
}

// MARK: - resolve JSON

extension SpecFile {
    /// Resolve pathProperties in all included specs than merge JSON
    func resolvedDictionary() -> JSONDictionary {
        var current: [SpecFile] = [self]
        var next: [SpecFile] = []
        var queue: [(json: JSONDictionary, filePath: Path)] = []
        var resolvedJsons: [Path: JSONDictionary] = [:]

        while !current.isEmpty {
            for spec in current {
                let fullPath = spec.source.filePath

                let json: JSONDictionary

                if spec.source.relativePath == "" {
                    json = spec.jsonDictionary
                } else if let cached = resolvedJsons[fullPath] {
                    json = cached
                } else {
                    json = Project.pathProperties.resolvingPaths(in: spec.jsonDictionary, relativeTo: spec.source.relativePath)
                    resolvedJsons[fullPath] = json
                }
                queue.append((json, fullPath))

                for subSpec in spec.subSpecs {
                    next.append(subSpec)
                }
            }
            current = next
            next.removeAll()
        }

        var seen = Set<Path>()

        // Spec should override subSpecs, that why we using reversed order:
        // [:] <- include <- .. <- include <- project
        return queue.reversed().reduce(into: [:]) {
            guard seen.insert($1.filePath).inserted else { return }

            $1.json.mergedSpecInplaceOverwriting(&$0)
        }
    }
}

// MARK: - Include

extension SpecFile {
    /// "include:" or "import:" spec section parser
    struct Include: Equatable {
        let path: Path
        /// Deprecated XcodeGen legacy
        let relativePaths: Bool
        let enable: Bool

        /// Memberwise initializer
        init(path: Path, relativePaths: Bool, enable: Bool = true) {
            self.path = path
            self.relativePaths = relativePaths
            self.enable = enable
        }

        /// Parser init
        init?(
            any: Any,
            relativePathsDefault: Bool
        ) {
            if let string = any as? String {
                path = Path(string)
                relativePaths = relativePathsDefault
                enable = true
            } else if let dictionary = any as? JSONDictionary, let path = dictionary["path"] as? String {
                self.path = Path(path)
                relativePaths = Self.resolveBoolean(dictionary, key: "relativePaths") ?? relativePathsDefault
                enable = Self.resolveBoolean(dictionary, key: "enable") ?? true
            } else {
                return nil
            }
        }

        static func parseFromSpec(_ specJson: JSONDictionary) -> [Include] {
            let imports = parseImports(specJson)
            if imports.isEmpty {
                return parseIncludes(specJson)
            } else {
                return imports
            }
        }

        private static func parseImports(_ specJson: JSONDictionary) -> [Include] {
            let json: Any? = specJson["import"]

            if let array = json as? [Any] {
                return array.compactMap { Include(any: $0, relativePathsDefault: false) }
            } else if let object = json, let include = Include(any: object, relativePathsDefault: false) {
                return [include]
            } else {
                return []
            }
        }

        /// Legacy
        private static func parseIncludes(_ specJson: JSONDictionary) -> [Include] {
            let json: Any? = specJson["include"]

            if let array = json as? [Any] {
                return array.compactMap { Include(any: $0, relativePathsDefault: true) }
            } else if let object = json, let include = Include(any: object, relativePathsDefault: true) {
                return [include]
            } else {
                return []
            }
        }

        private static func resolveBoolean(_ dictionary: [String: Any], key: String) -> Bool? {
            dictionary[key] as? Bool ?? (dictionary[key] as? NSString)?.boolValue
        }
    }
}

// MARK: - Source

extension SpecFile {
    /// ``Path`` to ``SpecFile`` and related dirs
    struct Source: Equatable {
        /// ``SpecFile`` absolute path.
        ///
        /// Example:
        /// ```
        /// /Users/18397633/Development/assistant-sdk-ios/Submodules/SDSoup/project.yml
        /// ```
        let filePath: Path

        /// For the root spec, this is the folder containing the ``SpecFile``.
        /// For subSpecs this is the path to the folder of the parent spec that is including this ``SpecFile``.
        ///
        /// Example:
        /// ```
        /// /Users/18397633/Development/assistant-sdk-ios/Submodules/SDSoup
        /// ```
        let basePath: Path

        /// ``PathProperty`` resolution anchor path.
        ///
        /// The relative path to use when resolving paths in the json dictionary.
        /// It is "" path when included with relativePaths disabled.
        ///
        /// Example:
        /// ```
        /// ../../templates/xcodegen
        /// ```
        let relativePath: Path

        /// ``SpecFile`` parent directory.
        var parentPath: Path { filePath.parent() }

        /// Memberwise initializer
        init(filePath: Path, basePath: Path, relativePath: Path) {
            self.filePath = filePath
            self.basePath = basePath
            self.relativePath = relativePath
        }

        /// Pathes for loading a project.yml ``SpecFile``
        static func project(_ path: Path) throws -> Source {
            Source(
                filePath: path,
                basePath: path.parent(),
                relativePath: ""
            )
        }

        /// Pathes for import in ``SpecFile`` (mergable "template")
        func include(_ include: Include) -> Source {
            if include.relativePaths {
                let includePath = parentPath + include.path
                return Source(
                    filePath: includePath,
                    basePath: basePath,
                    relativePath: (try? includePath.parent().relativePath(from: basePath))?.normalize() ?? ""
                )
            } else {
                return Source(
                    filePath: parentPath + include.path,
                    basePath: basePath,
                    relativePath: ""
                )
            }
        }
    }
}
