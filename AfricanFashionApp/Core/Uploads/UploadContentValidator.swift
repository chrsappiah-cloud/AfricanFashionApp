//
//  UploadContentValidator.swift
//  AfricanFashionApp
//

import Foundation
import ImageIO

enum UploadContentValidator: Sendable {
    enum ListingImageError: Error, LocalizedError {
        case notDecodableImage
        case tooSmall(width: Int, height: Int)

        var errorDescription: String? {
            switch self {
            case .notDecodableImage:
                "The file is not a supported raster image (JPEG/PNG/HEIF, etc.)."
            case .tooSmall(let width, let height):
                "Image is too small for a listing (\(width)×\(height)). Use at least about 800 px on the shortest side when possible."
            }
        }
    }

    /// Confirms bytes decode as an image and meet a minimum size. This does **not** prove subject matter
    /// (e.g. “authentic African fashion”); that belongs in human moderation or a server-side ML policy.
    nonisolated static func validateListingImageData(_ data: Data, minimumShortSide: Int = 480) throws {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ListingImageError.notDecodableImage
        }
        guard CGImageSourceGetCount(source) > 0 else {
            throw ListingImageError.notDecodableImage
        }
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let width = (props?[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? 0
        let height = (props?[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? 0
        guard width > 0, height > 0 else {
            throw ListingImageError.notDecodableImage
        }
        if min(width, height) < minimumShortSide {
            throw ListingImageError.tooSmall(width: width, height: height)
        }
    }
}
