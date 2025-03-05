//
//  ContentView.swift
//  ScriboBot
//
//  Created by HouPeihong on 2025/3/5.
//

import SwiftUI
import UIKit
import CoreML

class PencilTrackerView: UIView {
    private var drawingLayer: CAShapeLayer!
    private var currentPath: UIBezierPath?
    private var lastPoint: CGPoint?
    private var lastWidth: CGFloat = 1.0
    private var canvasImage: UIImage?
    private var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(captureImage(_:)),
            name: .captureDrawingImage,
            object: nil
        )
    }
    
    @objc private func captureImage(_ notification: Notification) {
        if let image = self.canvasImage {
            NotificationCenter.default.post(
                name: .didCaptureDrawingImage,
                object: nil,
                userInfo: ["image": image]
            )
        }
    }
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupView()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    private func setupView() {
        self.isMultipleTouchEnabled = false
        self.backgroundColor = .white
        
        // 设置绘图画布
        imageView = UIImageView(frame: self.bounds)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
    }
    
    private func computeLineWidth(for touch: UITouch) -> CGFloat {
        let force = touch.force
        let altitude = touch.altitudeAngle
        
        // 计算基础宽度（根据倾斜角度）
        let maxAltitude = CGFloat.pi / 2
        let altitudeFactor = 1.0 - (altitude / maxAltitude)
        let baseWidth = altitudeFactor * 20  // 最大宽度20
        
        // 根据压力调整宽度
        let forceMultiplier = force * 2  // 压力系数
        
        // 合并计算结果
        let totalWidth = baseWidth + forceMultiplier
        return max(totalWidth, 1.0)
    }
    
    private func drawLine(from start: CGPoint, to end: CGPoint, width: CGFloat) {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { ctx in
            // 绘制之前的图像
            if let canvasImage = canvasImage {
                canvasImage.draw(at: .zero)
            }
            
            // 设置毛笔效果参数
            UIColor.black.setStroke()
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            
            // 设置路径属性
            path.lineWidth = width
            path.lineCapStyle = .round  // 圆形线帽
            path.lineJoinStyle = .round  // 圆形连接
            
            // 添加阴影效果增强立体感
            ctx.cgContext.setShadow(
                offset: CGSize(width: 0, height: 1),
                blur: 1,
                color: UIColor.black.withAlphaComponent(0.3).cgColor
            )
            
            path.stroke()
        }
        
        // 更新画布
        canvasImage = image
        imageView.image = image
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastPoint = touch.location(in: self)
        lastWidth = computeLineWidth(for: touch)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let start = lastPoint else { return }
        
        let end = touch.location(in: self)
        let width = computeLineWidth(for: touch)
        
        // 使用插值让线条更平滑
        let intermediatePoints = interpolatePoints(from: start, to: end)
        for point in intermediatePoints {
            drawLine(from: start, to: point, width: width)
            lastPoint = point
        }
        
        // 更新数据并发送通知
        handleTouches(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPoint = nil
        handleTouches(touches)
    }
    
    private func interpolatePoints(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        var points = [CGPoint]()
        let distance = hypot(end.x - start.x, end.y - start.y)
        let steps = Int(distance / 2)
        
        for i in 0..<steps {
            let ratio = CGFloat(i) / CGFloat(steps)
            let x = start.x + (end.x - start.x) * ratio
            let y = start.y + (end.y - start.y) * ratio
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
    
    // 保留原有的数据采集逻辑
    private func handleTouches(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        
        if touch.type == .pencil || touch.type == .indirectPointer {
            let location = touch.location(in: self)
            let locinfo = String(format: "(%.2f, %.2f)", location.x, location.y)
            let force = touch.force
            let azimuth = String(format: "%.2f", touch.azimuthAngle(in: self))
            let altitude = String(format: "%.2f", touch.altitudeAngle)
            
            print("[\(touch.timestamp)]位置: \(locinfo), 压感: \(force), 笔尖方位角: \(azimuth), 笔尖倾斜角: \(altitude),")
            
            NotificationCenter.default.post(
                name: .pencilDataUpdate,
                object: nil,
                userInfo: [
                    "location": location,
                    "force": force,
                    "azimuth": touch.azimuthAngle(in: self),
                    "altitude": touch.altitudeAngle,
                    "timestamp": touch.timestamp
                ]
            )
        }
    }
}

// SwiftUI 包装视图
struct PencilTrackerViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> PencilTrackerView {
        PencilTrackerView()
    }
    
    func updateUIView(_ uiView: PencilTrackerView, context: Context) {}
}

// SwiftUI 显示界面
struct ContentView: View {
    @State private var lastForce: CGFloat = 0
    @State private var lastLocation: CGPoint = .zero
    @State private var lastAzimuth: CGFloat = 0
    @State private var lastAltitude: CGFloat = 0
    @State private var lastTimestamp: TimeInterval = 0
    @State private var recognizedText = ""
    
    var body: some View {
        VStack {
            Text("Apple Pencil 数据")
                .font(.title)
                .padding()
            
            PencilTrackerViewWrapper()
                .frame(height: 400)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .padding()
            
            VStack(alignment: .leading) {
                Text("最新数据：")
                Text("位置: \(String(format: "%.1f", lastLocation.x)), \(String(format: "%.1f", lastLocation.y))")
                Text("压感: \(String(format: "%.2f", lastForce))")
                Text("笔尖方位角: \(String(format: "%.2f", lastAzimuth))")
                Text("笔尖倾斜角: \(String(format: "%.2f", lastAltitude))")
                Text("时间戳: \(String(format: "%.3f", lastTimestamp))")
            }
            .padding()
            
            Button("识别文字") {
                NotificationCenter.default.post(
                    name: .captureDrawingImage,
                    object: nil
                )
            }
            .padding()
            
            Text("识别结果: \(recognizedText)")
                .font(.title2)
                .padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pencilDataUpdate)) { notification in
            if let location = notification.userInfo?["location"] as? CGPoint,
               let force = notification.userInfo?["force"] as? CGFloat,
               let azimuth = notification.userInfo?["azimuth"] as? CGFloat,
               let altitude = notification.userInfo?["altitude"] as? CGFloat,
               let timestamp = notification.userInfo?["timestamp"] as? TimeInterval {
                lastLocation = location
                lastForce = force
                lastAzimuth = azimuth
                lastAltitude = altitude
                lastTimestamp = timestamp
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCaptureDrawingImage)) { notification in
            guard let image = notification.userInfo?["image"] as? UIImage else { return }
            recognizeText(from: image)
        }
    }
    
    private func recognizeText(from image: UIImage) {
            // 图像预处理
        let croppedImage = cropToBounds(image: image)
        let modelSize = CGSize(width: 28, height: 28)
        let scaledImage = croppedImage.resized(to: modelSize)
        let grayImage = scaledImage.convertedToGrayScale()
        let invertedImage = grayImage.invertedColors() ?? grayImage
        
        if let ciImage = invertedImage.ciImage {
            let context = CIContext(options: nil)
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                // 使用 cgImage 继续处理
                print("okay!!")
                let width = Int(ciImage.extent.width)
                let height = Int(ciImage.extent.height)
                guard let pixelBuffer = cgImage.pixelBuffer(width: width, height: height) else {
                    recognizedText = "图像处理失败"
                    return
                }

                // 执行预测
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let model = try MNISTClassifier()
                        let prediction = try model.prediction(image: pixelBuffer)
                        DispatchQueue.main.async {
                            self.recognizedText = String(prediction.classLabel)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.recognizedText = "识别错误"
                        }
                    }
                }
//                processImage(cgImage: cgImage)
            } else {
                recognizedText = "CIContext转换失败"
            }
        } else {
            recognizedText = "CIImage不存在"
        }
        
        
        
    }
    
    private func cropToBounds(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bytesPerPixel = 1
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        var rawData = [UInt8](repeating: 0, count: width * height)
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return image }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        
        // 查找有效区域
        for y in 0..<height {
            for x in 0..<width {
                let pixelValue = rawData[y * width + x]
                if pixelValue < 255 { // 非白色像素
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }
        
        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        guard let croppedCGImage = cgImage.cropping(to: rect) else { return image }
        return UIImage(cgImage: croppedCGImage)
    }
}

// 通知扩展
extension Notification.Name {
    static let pencilDataUpdate = Notification.Name("pencilDataUpdate")
}

// 预览
#Preview {
    ContentView()
}
