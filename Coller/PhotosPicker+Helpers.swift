import Foundation
import UIKit

enum ImageDecodeError: Error {
    case invalidData
}

struct ImageDecoder {
    static func decode(_ data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else { throw ImageDecodeError.invalidData }
        return image
    }
}
