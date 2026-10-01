import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// Active background processing mode for the webcam picture-in-picture overlay.
public enum WebcamBackgroundMode: String, CaseIterable, Identifiable, Sendable {
    case none
    case blur
    case preset
    case customImage
    case cutout

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .none:        return "Normal"
        case .blur:        return "Blur"
        case .preset:      return "Virtual Backdrop"
        case .customImage: return "Custom Image"
        case .cutout:      return "Cutout (Silhouette)"
        }
    }
}

/// Blur strength options for background blurring.
public enum WebcamBlurStrength: String, CaseIterable, Identifiable, Sendable {
    case subtle
    case balanced
    case strong

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .subtle:   return "Subtle (10px)"
        case .balanced: return "Balanced (20px)"
        case .strong:   return "Strong (35px)"
        }
    }
    public var sigma: Double {
        switch self {
        case .subtle:   return 10.0
        case .balanced: return 20.0
        case .strong:   return 35.0
        }
    }
}

/// Built-in virtual background presets generated on-device with zero assets or network egress.
public enum WebcamBackgroundPreset: String, CaseIterable, Identifiable, Sendable {
    case warmStudio
    case coolSlate
    case modernMinimal
    case sunset
    case chromaGreen

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .warmStudio:    return "Warm Studio"
        case .coolSlate:     return "Cool Slate"
        case .modernMinimal: return "Modern Minimal"
        case .sunset:        return "Sunset"
        case .chromaGreen:   return "Green Screen"
        }
    }

    /// Renders a crisp background `CIImage` sized to the target dimensions.
    public func makeImage(size: CGSize) -> CIImage {
        let width = max(size.width, 100)
        let height = max(size.height, 100)
        let rect = CGRect(origin: .zero, size: CGSize(width: width, height: height))

        switch self {
        case .warmStudio:
            let filter = CIFilter.radialGradient()
            filter.center = CGPoint(x: width * 0.5, y: height * 0.6)
            filter.radius0 = Float(min(width, height) * 0.1)
            filter.radius1 = Float(max(width, height) * 0.9)
            filter.color0 = CIColor(red: 0.34, green: 0.26, blue: 0.28)
            filter.color1 = CIColor(red: 0.12, green: 0.10, blue: 0.13)
            return filter.outputImage?.cropped(to: rect) ?? CIImage(color: filter.color1).cropped(to: rect)

        case .coolSlate:
            let filter = CIFilter.linearGradient()
            filter.point0 = CGPoint(x: 0, y: height)
            filter.point1 = CGPoint(x: width, y: 0)
            filter.color0 = CIColor(red: 0.14, green: 0.20, blue: 0.28)
            filter.color1 = CIColor(red: 0.06, green: 0.08, blue: 0.14)
            return filter.outputImage?.cropped(to: rect) ?? CIImage(color: filter.color1).cropped(to: rect)

        case .modernMinimal:
            let filter = CIFilter.radialGradient()
            filter.center = CGPoint(x: width * 0.5, y: height * 0.5)
            filter.radius0 = Float(min(width, height) * 0.15)
            filter.radius1 = Float(max(width, height) * 0.85)
            filter.color0 = CIColor(red: 0.28, green: 0.28, blue: 0.31)
            filter.color1 = CIColor(red: 0.14, green: 0.14, blue: 0.16)
            return filter.outputImage?.cropped(to: rect) ?? CIImage(color: filter.color1).cropped(to: rect)

        case .sunset:
            let filter = CIFilter.linearGradient()
            filter.point0 = CGPoint(x: 0, y: 0)
            filter.point1 = CGPoint(x: width, y: height)
            filter.color0 = CIColor(red: 0.44, green: 0.18, blue: 0.28)
            filter.color1 = CIColor(red: 0.16, green: 0.12, blue: 0.30)
            return filter.outputImage?.cropped(to: rect) ?? CIImage(color: filter.color1).cropped(to: rect)

        case .chromaGreen:
            return CIImage(color: CIColor(red: 0.0, green: 1.0, blue: 0.0)).cropped(to: rect)
        }
    }
}
