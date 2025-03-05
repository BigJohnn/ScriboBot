//
//  UIImageEx.swift
//  ScriboBot
//
//  Created by HouPeihong on 2025/3/5.
//
import UIKit

extension UIImage {
    // 调整尺寸
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // 转换为灰度
    func convertedToGrayScale() -> UIImage {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectMono") else { return self }
        currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        guard let output = currentFilter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else { return self }
        return UIImage(cgImage: cgImage)
    }
    
    // 颜色反转
    func invertedColors() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else { return nil }
        return UIImage(ciImage: outputImage)
    }
    
    // 转换为CVPixelBuffer
    func pixelBuffer() -> CVPixelBuffer? {
        let size = self.size
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_OneComponent8,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer!, .readOnly) }
        
        if let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer!) {
            let grayColorSpace = CGColorSpaceCreateDeviceGray()
            let context = CGContext(
                data: baseAddress,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                space: grayColorSpace,
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            )
            
            context?.draw(self.cgImage!, in: CGRect(origin: .zero, size: size))
        }
        
        return pixelBuffer
    }
}
