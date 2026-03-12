import Foundation
import JSONutils

struct TemplateStructure: Hashable, Sendable {
    let baseKey: String
    let templatesKey: String
    let nameToReplace: String
}

extension Target {
    static func resolveTargetTemplates(_ jsonDictionary: inout JSONDictionary) {
        resolveTemplates(
            jsonDictionary: &jsonDictionary,
            templateStructure: TemplateStructure(
                baseKey: "targets",
                templatesKey: "targetTemplates",
                nameToReplace: "target_name"
            )
        )
    }
}

extension Scheme {
    static func resolveSchemeTemplates(_ jsonDictionary: inout JSONDictionary) {
        resolveTemplates(
            jsonDictionary: &jsonDictionary,
            templateStructure: TemplateStructure(
                baseKey: "schemes",
                templatesKey: "schemeTemplates",
                nameToReplace: "scheme_name"
            )
        )
    }
}

private func resolveTemplates(jsonDictionary: inout JSONDictionary, templateStructure: TemplateStructure) {
    guard var baseDictionary: [String: JSONDictionary] = jsonDictionary[templateStructure.baseKey] as? [String: JSONDictionary] else {
        return
    }

    guard let templatesDictionary: [String: JSONDictionary] = jsonDictionary[templateStructure.templatesKey] as? [String: JSONDictionary] else {
        return
    }

    // Recursively collects all nested template names of a given dictionary.
    func collectTemplates(
        of jsonDictionary: inout JSONDictionary,
        into allTemplates: inout [String],
        insertAt insertionIndex: inout Int
    ) {
        guard let templates = jsonDictionary["templates"] as? [String] else {
            return
        }
        for template in templates where !allTemplates.contains(template) {
            guard var templateDictionary = templatesDictionary[template] else {
                continue
            }
            allTemplates.insert(template, at: insertionIndex)
            collectTemplates(of: &templateDictionary, into: &allTemplates, insertAt: &insertionIndex)
            insertionIndex += 1
        }
    }

    var templateMergeCache: [[String]: JSONDictionary] = [:]

    for (referenceName, var reference) in baseDictionary {
        guard let topLevelTemplates = reference["templates"] as? [String], !topLevelTemplates.isEmpty else {
            continue
        }
        let templatesDict = templateMergeCache[topLevelTemplates] ?? {
            var templates: [String] = []
            var index = 0
            collectTemplates(of: &reference, into: &templates, insertAt: &index)
            let result: JSONDictionary = templates.reduce(into: [:]) {
                templatesDictionary[$1]?.mergedSpecInplaceOverwriting(&$0)
            }
            templateMergeCache[topLevelTemplates] = result
            return result
        }()

        reference = reference.mergedSpecOverwriting(templatesDict)
        reference = reference.expandVariables([templateStructure.nameToReplace: referenceName])

        if let templateAttributes = reference["templateAttributes"] as? [String: String] {
            reference = reference.expandVariables(templateAttributes)
        }
        baseDictionary[referenceName] = reference
    }

    jsonDictionary[templateStructure.baseKey] = baseDictionary
}
