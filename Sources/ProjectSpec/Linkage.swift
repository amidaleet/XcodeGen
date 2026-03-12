import Foundation
import XcodeProj

public enum Linkage: Hashable, Sendable {
    case dynamic
    case `static`
    case none
}

extension Target {
    public var defaultLinkage: Linkage {
        switch type {
        case .none,
             .appExtension,
             .application,
             .bundle,
             .commandLineTool,
             .instrumentsPackage,
             .intentsServiceExtension,
             .messagesApplication,
             .messagesExtension,
             .metalLibrary,
             .ocUnitTestBundle,
             .onDemandInstallCapableApplication,
             .stickerPack,
             .tvExtension,
             .uiTestBundle,
             .unitTestBundle,
             .watchApp,
             .watchExtension,
             .watch2App,
             .watch2AppContainer,
             .watch2Extension,
             .xcodeExtension,
             .xpcService,
             .systemExtension,
             .driverExtension,
             .extensionKitExtension:
            .none
        case .framework,
             .xcFramework:
            // Check the MACH_O_TYPE for "Static Framework"
            if settings.buildSettings.machOType == "staticlib" {
                .static
            } else {
                .dynamic
            }
        case .dynamicLibrary:
            .dynamic
        case .staticLibrary,
             .staticFramework:
            .static
        }
    }
}

extension BuildSettings {
    fileprivate var machOType: String? {
        self["MACH_O_TYPE"]?.stringValue
    }
}
