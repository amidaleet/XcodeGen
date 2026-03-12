import Foundation
import Version

public struct SpecValidationError: Error, CustomStringConvertible, Sendable {
    public var errors: [ValidationError]

    public init(errors: [ValidationError]) {
        self.errors = errors
    }

    public enum ValidationError: Hashable, Error, CustomStringConvertible, @unchecked Sendable {
        case invalidXcodeGenVersion(minimumVersion: Version, version: Version)
        case invalidSDKDependency(target: String, dependency: String)
        case invalidTargetDependency(target: String, dependency: String)
        case invalidTargetSource(target: String, source: String)
        case invalidTargetConfigFile(target: String, configFile: String, config: String)
        case invalidTargetSchemeConfigVariant(target: String, configVariant: String, configType: ConfigType)
        case invalidTargetSchemeTest(target: String, testTarget: String)
        case invalidTargetPlatformForSupportedDestinations(target: String)
        case unexpectedTargetPlatformForSupportedDestinations(target: String, platform: Platform)
        case containsWatchOSDestinationForMultiplatformApp(target: String)
        case multipleMacPlatformsInSupportedDestinations(target: String)
        case missingTargetPlatformInSupportedDestinations(target: String, platform: Platform)
        case invalidSchemeTarget(scheme: String, target: String, action: String)
        case invalidSchemeConfig(scheme: String, config: String)
        case invalidSwiftPackage(name: String, target: String)
        case invalidPackageDependencyReference(name: String)
        case invalidLocalPackage(String)
        case invalidConfigFile(configFile: String, config: String)
        case invalidBuildSettingConfig(String)
        case invalidSettingsGroup(String)
        case invalidBuildScriptPath(target: String, name: String?, path: String)
        case invalidFileGroup(String)
        case invalidConfigFileConfig(String)
        case missingConfigForTargetScheme(target: String, configType: ConfigType)
        case missingDefaultConfig(configName: String)
        case invalidPerConfigSettings
        case invalidProjectReference(scheme: String, reference: String)
        case invalidProjectReferencePath(ProjectReference)
        case invalidTestPlan(TestPlan)
        case multipleDefaultTestPlans
        case duplicateDependencies(target: String, dependencyReference: String)
        case invalidPluginPackageReference(plugin: String, package: String)
        case emptySourcePath(target: String)

        public var description: String {
            switch self {
            case let .invalidXcodeGenVersion(minimumVersion, version):
                "XcodeGen version is \(version), but minimum required version specified as \(minimumVersion)"
            case let .invalidSDKDependency(target, dependency):
                "Target \(target.quoted) has invalid sdk dependency: \(dependency.quoted). It must be a full path or have the following extensions: .framework, .dylib, .tbd"
            case let .invalidTargetDependency(target, dependency):
                "Target \(target.quoted) has invalid dependency: \(dependency.quoted)"
            case let .invalidTargetConfigFile(target, configFile, config):
                "Target \(target.quoted) has invalid config file path \(configFile.quoted) for config \(config.quoted)"
            case let .invalidTargetSource(target, source):
                "Target \(target.quoted) has a missing source directory \(source.quoted)"
            case let .invalidTargetSchemeConfigVariant(target, configVariant, configType):
                "Target \(target.quoted) has an invalid scheme config variant which requires a config that has a \(configType.rawValue.quoted) type and contains the name \(configVariant.quoted)"
            case let .invalidTargetSchemeTest(target, test):
                "Target \(target.quoted) scheme has invalid test \(test.quoted)"
            case let .invalidTargetPlatformForSupportedDestinations(target):
                "Target \(target.quoted) has supported destinations that require a target platform iOS or auto"
            case let .unexpectedTargetPlatformForSupportedDestinations(target, platform):
                "Target \(target.quoted) has platform \(platform.rawValue.quoted) that does not expect supported destinations"
            case let .multipleMacPlatformsInSupportedDestinations(target):
                "Target \(target.quoted) has multiple definitions of mac platforms in supported destinations"
            case let .missingTargetPlatformInSupportedDestinations(target, platform):
                "Target \(target.quoted) has platform \(platform.rawValue.quoted) that is missing in supported destinations"
            case let .containsWatchOSDestinationForMultiplatformApp(target):
                "Multiplatform app \(target.quoted) cannot contain watchOS in \"supportedDestinations\". Create a separate target using \"platform\" for watchOS apps"
            case let .invalidConfigFile(configFile, config):
                "Invalid config file \(configFile.quoted) for config \(config.quoted)"
            case let .invalidSchemeTarget(scheme, target, action):
                "Scheme \(scheme.quoted) has invalid \(action) target \(target.quoted)"
            case let .invalidSchemeConfig(scheme, config):
                "Scheme \(scheme.quoted) has invalid build configuration \(config.quoted)"
            case let .invalidBuildSettingConfig(config):
                "Build setting has invalid build configuration \(config.quoted)"
            case let .invalidSettingsGroup(group):
                "Invalid settings group \(group.quoted)"
            case let .invalidBuildScriptPath(target, name, path):
                "Target \(target.quoted) has a script \(name != nil ? "\(name!.quoted) which has a " : "")path that doesn't exist \(path.quoted)"
            case let .invalidFileGroup(group):
                "Invalid file group \(group.quoted)"
            case let .invalidConfigFileConfig(config):
                "Config file has invalid config \(config.quoted)"
            case let .invalidSwiftPackage(name, target):
                "Target \(target.quoted) has an invalid package dependency \(name.quoted)"
            case let .invalidLocalPackage(path):
                "Invalid local package \(path.quoted)"
            case let .invalidPackageDependencyReference(name):
                "Package reference \(name) must be specified as package dependency, not target"
            case let .missingConfigForTargetScheme(target, configType):
                "Target \(target.quoted) is missing a config of type \(configType.rawValue) to generate its scheme"
            case let .missingDefaultConfig(name):
                "Default configuration \(name) doesn't exist"
            case .invalidPerConfigSettings:
                "Settings that are for a specific config must go in \"configs\". \"base\" can be used for common settings"
            case let .invalidProjectReference(scheme, project):
                "Scheme \(scheme.quoted) has invalid project reference \(project.quoted)"
            case let .invalidProjectReferencePath(reference):
                "Project reference \(reference.name) has a project file path that doesn't exist \"\(reference.path)\""
            case let .invalidTestPlan(testPlan):
                "Test plan path \"\(testPlan.path)\" doesn't exist"
            case .multipleDefaultTestPlans:
                "Your test plans contain more than one default test plan"
            case let .duplicateDependencies(target, dependencyReference):
                "Target \(target.quoted) has the dependency \(dependencyReference.quoted) multiple times"
            case let .invalidPluginPackageReference(plugin, package):
                "Plugin \(plugin) has invalid package reference \(package)"
            case let .emptySourcePath(target):
                "Target \(target.quoted) has an empty source path entry"
            }
        }
    }

    public var description: String {
        let title: String
        if errors.count == 1 {
            title = "Spec validation error: "
        } else {
            title = "\(errors.count) Spec validations errors:\n\t- "
        }
        return "\(title)" + errors.map(\.description).joined(separator: "\n\t- ")
    }
}
