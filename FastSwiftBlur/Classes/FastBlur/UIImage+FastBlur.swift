//
// In this file implemented very fast cached blurring method.
// It uses "vImage" methods of great Accelerate framework
//
// Created by Maxim on 08/05/2018.
// Copyright (c) 2018 Aspirity. All rights reserved.
//

import UIKit
import Accelerate

/*
* This worker wraps an image and creates cache for fast blurring
*/
public class FastBlurWorker {

    // --
    let image: UIImage
    
    // --
    private var cachedSize: CGSize?
    private var cache: FastBlurImageCache?

    // --
    init(image: UIImage) {
        self.image = image
    }

    // -- public methods
    
    public func fastBlur(with radius: Float, scaledTo size: CGSize) -> UIImage {
        if cachedSize != size || cache == nil  {
            guard let sourceCGImage: CGImage = image.cgImage else {
                log("error: sourceRef is nil")
                return image
            }

            cache = FastBlurImageCache(source: sourceCGImage, scaledToSize: size)
            cachedSize = size
        }

        return image.fastBlur(radius: radius, scaledTo: size, cache: cache)
    }

}

// --

public extension UIImage {

    /*
     * Workaround for vImageTentConvolve
     * It uses cache for input source
     */
    public func fastBlur(radius: Float, scaledTo size: CGSize) -> UIImage {
        return fastBlur(radius: radius, scaledTo: size, cache: nil)
    }
    
    internal func fastBlur(radius: Float, scaledTo size: CGSize, cache: FastBlurImageCache?) -> UIImage {
        guard radius > 0 else {
            return self
        }
        // -- setup for input
        guard let sourceCGImage: CGImage = self.cgImage else {
            log("error: sourceRef is nil")
            return self
        }

        let srcCache = cache ?? FastBlurImageCache(source: sourceCGImage, scaledToSize: size)

        guard var srcBuffer = srcCache.scaledNonBlurredBuffer else {
            log("error: srcBuffer is nil")
            return self
        }

        // -- setup for output
        let pixelBuffer = malloc(srcBuffer.rowBytes * Int(srcBuffer.height))
        defer {
            free(pixelBuffer)
        }

        var outBuffer = vImage_Buffer(data: pixelBuffer, height: srcBuffer.height, width: srcBuffer.width, rowBytes: srcBuffer.rowBytes)

        // -- do blur

        var boxSize = UInt32(floor(radius * FastBlurConsts.GAUSIAN_TO_TENT_RADIUS_RADIO))
        boxSize |= 1;

        let error = vImageTentConvolve_ARGB8888(&srcBuffer, &outBuffer, nil, 0, 0, boxSize, boxSize, nil, UInt32(kvImageEdgeExtend))

        guard error == vImage_Error(kvImageNoError) else {
            log("error in tent convolve: \(error)")
            return self
        }

        // -- make result image
        var format = FastBlurConsts.arg888format()
        guard let cgResult = vImageCreateCGImageFromBuffer(&outBuffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil) else {
            log("error in create image from buffer: \(error)")
            return self
        }

        let result = UIImage(cgImage: cgResult.takeRetainedValue(), scale: self.scale, orientation: self.imageOrientation)

        return result
    }

}

// --

/*
* Workaround for vImage_Buffer. It is cached input source for vImageTentConvolve
*/
class FastBlurImageCache {

    private(set) var scaledNonBlurredBuffer: vImage_Buffer?

    /*
    * Check scale needs, it it necessary than it scales via vImageScale
    */
    init(source: CGImage, scaledToSize: CGSize) {
        // -- set up input
        var srcBuffer = vImage_Buffer()

        var format = FastBlurConsts.arg888format()
        var error = vImageBuffer_InitWithCGImage(&srcBuffer, &format, nil, source, vImage_Flags(kvImageNoFlags))

        guard error == vImage_Error(kvImageNoError) else {
            log("error in init image buffer: \(error)")
            free(srcBuffer.data)
            return
        }

        // -- scale needs
        var ratio: CGFloat = 1
        let sourceWidth = CGFloat(source.width)
        let sourceHeight = CGFloat(source.height)

        if sourceWidth > scaledToSize.width && sourceHeight > scaledToSize.height {
            ratio = max(scaledToSize.width / sourceWidth, scaledToSize.height / sourceHeight)
        }

        if ratio == 1 {
            scaledNonBlurredBuffer = srcBuffer
        } else {
            // -- do scale
            let dstWidth = vImagePixelCount(sourceWidth * ratio)
            let dstHeight = vImagePixelCount(sourceHeight * ratio)
            let dstBytesPerPixel = source.bytesPerRow / source.width
            let dstBytesPerRow = dstBytesPerPixel * Int(dstWidth)
            let dstData = malloc( dstBytesPerRow * Int(dstHeight) )

            var dstBuffer = vImage_Buffer(data: dstData, height: dstHeight, width: dstWidth, rowBytes: dstBytesPerRow)

            error = vImageScale_ARGB8888(&srcBuffer, &dstBuffer, nil, UInt32(kvImageHighQualityResampling))
            free(srcBuffer.data)

            guard error == vImage_Error(kvImageNoError) else {
                log("error in scale image: \(error)")
                free(dstData)
                return
            }

            scaledNonBlurredBuffer = dstBuffer
        }
    }

    deinit {
        if let buffer = scaledNonBlurredBuffer {
            free(buffer.data)
        }
    }

}

// --

fileprivate class FastBlurConsts {

    static let GAUSIAN_TO_TENT_RADIUS_RADIO: Float = 5.0

    static func arg888format() -> vImage_CGImageFormat {
        return vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                colorSpace: nil,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue),
                version: 0,
                decode: nil,
                renderingIntent: .defaultIntent
        )
    }

}
