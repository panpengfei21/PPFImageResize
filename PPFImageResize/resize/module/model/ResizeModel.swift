//
//  resizeModel.swift
//  PPFImageResize
//
//  Created by 潘鹏飞 on 2019/7/3.
//  Copyright © 2019 潘鹏飞. All rights reserved.
//

import Cocoa

class ResizeModel: NSObject {
    
    enum TargetType:Equatable {
        case iOSIcon
        case macOSIcon
        case custom(width:Double,height:Double)
        
        static func == (lhs: TargetType, rhs: TargetType) -> Bool{
            switch (lhs,rhs) {
            case (.iOSIcon,.iOSIcon):
                return true
            case (.macOSIcon,.macOSIcon):
                return true
            case (.custom(_,_),.custom( _, _)):
                return true
            default:
                return false
            }
        }
        
        func targetSizes() -> [NSSize] {
            switch self {
            case .iOSIcon:
                return [NSSize(width: 40, height: 40),
                        NSSize(width: 60, height: 60),
                        NSSize(width: 58, height: 58),
                        NSSize(width: 87, height: 87),
                        NSSize(width: 80, height: 80),
                        NSSize(width: 120, height: 120),
                        NSSize(width: 180, height: 180),
                        NSSize(width: 29, height: 29),
                        NSSize(width: 29 * 2, height: 29 * 2),
                        NSSize(width: 76, height: 76),
                        NSSize(width: 76 * 2, height: 76 * 2),
                        NSSize(width: 83.5 * 2, height: 83.5 * 2),
                        NSSize(width: 1024, height: 1024)]
            case .macOSIcon:
                return [NSSize(width: 16, height: 16),
                        NSSize(width: 16 * 2, height: 16 * 2),
                        NSSize(width: 32 * 2, height: 32 * 2),
                        NSSize(width: 128, height: 128),
                        NSSize(width: 128 * 2, height: 128 * 2),
                        NSSize(width: 256 * 2, height: 256 * 2),
                        NSSize(width: 512 * 2, height: 512 * 2)]
            case let .custom(width: width, height: height):
                return [NSSize(width: width, height: height)]
            }
        }
    }
    
    var setTargetTypeBlock:((_ old:TargetType,_ new:TargetType)->())?
    
    
    @objc dynamic var errorStr:String?
//    /// 原图
//    var originIV:NSImage?
    /// 原图路径
    var originImagePath:URL?
    /// 目标文件夹路径
    @objc var targetFolderPath:URL?
    /// 目标类型
    var targetType:TargetType = .iOSIcon {
        didSet {
            setTargetTypeBlock?(oldValue,targetType)
        }
    }
    
    func convert() {
        errorStr = nil
        guard let url = originImagePath , let image = NSImage(contentsOf: url) else{
            errorStr = "请选择图片."
            return
        }
        
        for size in targetType.targetSizes() {
            let r = image.resize(size, isPixels: true)
            saveImage(r)
        }
    }
    
    
    @discardableResult
    func saveImage(_ image:NSImage) -> Bool{
        guard var target = targetFolderPath else {
            errorStr = "不知道保存在哪里"
            return false
        }
        guard let data = image.tiffRepresentation else{
            return false
        }
        guard let imageRep = NSBitmapImageRep(data: data) else{
            return false
        }
        imageRep.size = image.size
        
        ///////////png
        guard let pngData = imageRep.representation(using: .png, properties: [:]) else{
            return false
        }
        ///////////jpg
//
//        NSDictionary *imageProps = nil;
//
//        NSNumber *quality = [NSNumber numberWithFloat:.85];
//
//        imageProps = [NSDictionary dictionaryWithObject:quality forKey:NSImageCompressionFactor];
//
//        imageData1 = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
        
        let nf = NumberFormatter()
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        
        let width = nf.string(from: NSNumber(value: Double(image.size.width)))!
        let height = nf.string(from: NSNumber(value: Double(image.size.height)))!
        target.appendPathComponent("\(width)X\(height).png")
        
        do {
            try pngData.write(to:  target)
            return true
        }catch {
            errorStr = error.localizedDescription
            return false
        }
    }
}


extension NSImage {
    
    func resize(_ to: CGSize, isPixels: Bool = false) -> NSImage {
        
        var toSize = to
        let screenScale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0
        
        if isPixels {
            
            toSize.width = to.width / screenScale
            toSize.height = to.height / screenScale
        }
        
        let toRect = NSRect(x: 0, y: 0, width: toSize.width, height: toSize.height)
        let fromRect =  NSRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let newImage = NSImage(size: toRect.size)
        newImage.lockFocus()
        draw(in: toRect, from: fromRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
    }
}
