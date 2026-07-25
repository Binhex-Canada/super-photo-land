import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

public struct Photo {
    public let originalImage: NSImage
    public let ciImage: CIImage

    public init(url: URL) throws {
        guard let image = NSImage(contentsOf: url) else {
            throw PhotoEditorError.imageLoadFailed
        }

        guard let tiffData = image.tiffRepresentation,
              let ciImage = CIImage(data: tiffData)
        else {
            throw PhotoEditorError.imageProcessingFailed
        }

        self.originalImage = image
        self.ciImage = ciImage
    }
}

public enum PhotoFilter: String, CaseIterable, Identifiable {
    case none
    case noir
    case chrome
    case sepia
    case vivid

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .noir: return "Noir"
        case .chrome: return "Chrome"
        case .sepia: return "Sepia"
        case .vivid: return "Vivid"
        }
    }

    func apply(to image: CIImage) throws -> CIImage {
        switch self {
        case .none:
            return image
        case .noir:
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = image
            return try filter.outputImage.orThrow()
        case .chrome:
            let filter = CIFilter.photoEffectChrome()
            filter.inputImage = image
            return try filter.outputImage.orThrow()
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = image
            filter.intensity = 0.8
            return try filter.outputImage.orThrow()
        case .vivid:
            let filter = CIFilter.vibrance()
            filter.inputImage = image
            filter.amount = 0.8
            return try filter.outputImage.orThrow()
        }
    }
}

public struct ImageEdits: Equatable {
    public var exposure: Double = 0
    public var saturation: Double = 1
    public var contrast: Double = 1
    public var filter: PhotoFilter = .none

    public init(exposure: Double = 0, saturation: Double = 1, contrast: Double = 1, filter: PhotoFilter = .none) {
        self.exposure = exposure
        self.saturation = saturation
        self.contrast = contrast
        self.filter = filter
    }
}

public enum PhotoEditorError: Error, LocalizedError {
    case imageLoadFailed
    case imageProcessingFailed
    case renderingFailed
    case exportFailed

    public var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "The selected image could not be loaded."
        case .imageProcessingFailed:
            return "The image could not be converted for processing."
        case .renderingFailed:
            return "The image editor could not render the result."
        case .exportFailed:
            return "The edited image could not be exported."
        }
    }
}

extension Optional {
    func orThrow(_ error: @autoclosure () -> Error = PhotoEditorError.renderingFailed) throws -> Wrapped {
        switch self {
        case .some(let value): return value
        case .none: throw error()
        }
    }
}

public struct ImageEditor {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    public static func applyEdits(to photo: Photo, edits: ImageEdits) throws -> NSImage {
        let exposureFilter = CIFilter.exposureAdjust()
        exposureFilter.inputImage = photo.ciImage
        exposureFilter.ev = Float(edits.exposure)

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = try exposureFilter.outputImage.orThrow()
        colorControls.saturation = Float(edits.saturation)
        colorControls.contrast = Float(edits.contrast)

        var outputImage = try colorControls.outputImage.orThrow()
        outputImage = try edits.filter.apply(to: outputImage)

        return try render(ciImage: outputImage, size: photo.originalImage.size)
    }

    private static func render(ciImage: CIImage, size: NSSize) throws -> NSImage {
        let imageRect = ciImage.extent
        guard
            let cgImage = ciContext.createCGImage(ciImage, from: imageRect)
        else {
            throw PhotoEditorError.renderingFailed
        }

        let nsImage = NSImage(size: size)
        nsImage.addRepresentation(NSBitmapImageRep(cgImage: cgImage))
        return nsImage
    }
}
