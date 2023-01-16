//
//  MTLTexture+Extensions.swift
//  MetalScroll
//
//  Created by Артём on 28.05.2022.
//

import CoreGraphics
import Metal
import UIKit

public extension MTLTexture {
    var ratio: CGFloat {
        CGFloat(width) / CGFloat(height)
    }
    
    var size: float2 {
        .init(x: Float(width), y: Float(height))
    }
    
    var image: UIImage? {
        assert(pixelFormat == .rgba8Unorm)

        let pixelByteCount = 4 * MemoryLayout<UInt8>.size
        let imageBytesPerRow = width * pixelByteCount
        let imageByteCount = imageBytesPerRow * height
        let imageBytes = UnsafeMutableRawPointer.allocate(byteCount: imageByteCount, alignment: pixelByteCount)
        defer {
            imageBytes.deallocate()
        }

        getBytes(imageBytes,
                 bytesPerRow: imageBytesPerRow,
                 from: MTLRegionMake2D(0, 0, width, height),
                 mipmapLevel: 0)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB) else { return nil }
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let bitmapContext = CGContext(data: imageBytes,
                                            width: width,
                                            height: height,
                                            bitsPerComponent: 8,
                                            bytesPerRow: imageBytesPerRow,
                                            space: colorSpace,
                                            bitmapInfo: bitmapInfo) else { return nil }
        bitmapContext.data?.copyMemory(from: imageBytes, byteCount: imageByteCount)
        guard let image = bitmapContext.makeImage() else { return nil }
        return UIImage(cgImage: image)
    }
}
