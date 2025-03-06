//
//  CGImageEx.swift
//  ScriboBot
//
//  Created by HouPeihong on 2025/3/5.
//

import Foundation

import CoreGraphics
import CoreVideo
import CoreImage
import UIKit
extension CGImage {
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB, // 或者选择其他合适的像素格式
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

        let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

//        return pixelBuffer
        // 直接使用 CIImage(cgImage:)，不需要 if let
        let ciImage = CIImage(cgImage: self)

        // 转换为灰度图像
        let grayCIImage = ciImage.applyingFilter("CIColorControls", parameters: ["inputSaturation": 0])
        
        // 从灰度 CIImage 创建 CGImage
        let cicontext = CIContext()
        if let grayCGImage = cicontext.createCGImage(grayCIImage, from: grayCIImage.extent) {
            // 调整图像尺寸
            let targetSize = CGSize(width: 28, height: 28) // MNIST 模型期望的尺寸

            // 使用 CoreGraphics 进行图像缩放
            if let resizedCGImage = resizeCGImage(grayCGImage, to: targetSize) {
                // 创建灰度 CVPixelBuffer
                var resizedPixelBuffer: CVPixelBuffer?
                let resizedAttributes: [String: Any] = [
                    kCVPixelBufferCGImageCompatibilityKey as String: true,
                    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
                ]

                let resizedStatus = CVPixelBufferCreate(
                    kCFAllocatorDefault,
                    Int(targetSize.width),
                    Int(targetSize.height),
                    kCVPixelFormatType_OneComponent8, // 使用灰度像素格式
                    resizedAttributes as CFDictionary,
                    &resizedPixelBuffer
                )

                guard resizedStatus == kCVReturnSuccess, let resizedPixelBuffer = resizedPixelBuffer else {
                    print("Error: Resized CVPixelBufferCreate failed with status \(resizedStatus)")
                    return nil
                }

                CVPixelBufferLockBaseAddress(resizedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                let resizedPixelData = CVPixelBufferGetBaseAddress(resizedPixelBuffer)

                let resizedContext = CGContext(
                    data: resizedPixelData,
                    width: Int(targetSize.width),
                    height: Int(targetSize.height),
                    bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(resizedPixelBuffer),
                    space: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: CGImageAlphaInfo.none.rawValue
                )

                resizedContext?.draw(resizedCGImage, in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))

                CVPixelBufferUnlockBaseAddress(resizedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

                return resizedPixelBuffer
            } else {
                print("Error: Resizing CGImage failed")
                return nil
            }
        } else {
            print("Error: CIContext.createCGImage failed")
            return nil
        }
    }
    
    // 使用 CoreGraphics 进行图像缩放
        private func resizeCGImage(_ image: CGImage, to size: CGSize) -> CGImage? {
            let width = Int(size.width)
            let height = Int(size.height)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue

            if let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo) {
                context.interpolationQuality = .high
                context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                return context.makeImage()
            }
            return nil
        }

}
