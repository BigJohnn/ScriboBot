////
////  ContentView.swift
////  ScriboBot
////
////  Created by HouPeihong on 2025/3/5.
////
//
//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    ContentView()
//}

import SwiftUI
import UIKit

// UIKit 自定义视图
class PencilTrackerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.isMultipleTouchEnabled = false
        self.backgroundColor = .white
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
    
    private func handleTouches(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        
        // 检查是否为 Apple Pencil 输入
        if touch.type == .pencil || touch.type == .indirectPointer {
            let location = touch.location(in: self)
            let force = touch.force
            
            // 打印数据
            print("[\(touch.timestamp)]位置: \(location), 压感: \(force)")
            
            // 更新 SwiftUI 显示（如果需要）
            NotificationCenter.default.post(
                name: .pencilDataUpdate,
                object: nil,
                userInfo: ["location": location, "force": force]
            )
        }
        else {
            print("touch type: \(touch.type)")
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
            }
            .padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pencilDataUpdate)) { notification in
            if let location = notification.userInfo?["location"] as? CGPoint,
               let force = notification.userInfo?["force"] as? CGFloat {
                lastLocation = location
                lastForce = force
            }
        }
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
