import Foundation
import ProjectSpec
import XcodeProj

public enum SettingsPresetFile {
    case config(ConfigType)
    case platform(Platform)
    case supportedDestination(SupportedDestination)
    case product(PBXProductType)
    case productPlatform(PBXProductType, Platform)
    case base

    var path: String {
        switch self {
        case let .config(config): "Configs/\(config.rawValue)"
        case let .platform(platform): "Platforms/\(platform.rawValue)"
        case let .supportedDestination(supportedDestination): "SupportedDestinations/\(supportedDestination.rawValue)"
        case let .product(product): "Products/\(product.name)"
        case let .productPlatform(product, platform): "Product_Platform/\(product.name)_\(platform.rawValue)"
        case .base: "base"
        }
    }

    var name: String {
        switch self {
        case let .config(config): "\(config.rawValue) config"
        case let .platform(platform): platform.rawValue
        case let .supportedDestination(supportedDestination): supportedDestination.rawValue
        case let .product(product): product.name
        case let .productPlatform(product, platform): "\(platform) \(product)"
        case .base: "base"
        }
    }
}
