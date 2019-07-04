//
//  ResizeViewController.swift
//  PPFImageResize
//
//  Created by 潘鹏飞 on 2019/7/3.
//  Copyright © 2019 潘鹏飞. All rights reserved.
//

import Cocoa

class ResizeViewController: NSViewController {

    @IBOutlet weak var originIV: NSImageView!
    @IBOutlet weak var appIcon: NSButton!
    @IBOutlet weak var customB: NSButton!
    @IBOutlet weak var macOSIconB: NSButton!
    
    @IBOutlet weak var originImagePathTF: NSTextField!
    @IBOutlet weak var targetImagePathTF: NSTextField!
    @IBOutlet weak var widthTF: NSTextField!
    @IBOutlet weak var heightTF: NSTextField!
    @IBOutlet weak var errorLabel: NSTextField!
    
    let model = ResizeModel()
    
    var observers:[NSKeyValueObservation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeUIs()
        
    }
    override func viewWillAppear() {
        super.viewWillAppear()
        print(#function)
        addObservers()
    }
    override func viewWillDisappear() {
        super.viewWillDisappear()
        print(#function)
        removeObservers()
    }
    
    private func initializeUIs() {
        if let url = model.originImagePath {
            originIV.image = NSImage(contentsOf: url)
        }
        updateRadio(type: model.targetType)
    }
    
    /// 更新Radio
    private func updateRadio(type:ResizeModel.TargetType){
        switch type {
        case .iOSIcon:
            appIcon.state = .on
            customB.state = .off
            macOSIconB.state = .off
            
            widthTF.isEnabled = false
            heightTF.isEnabled = false
        case .custom(width: _, height: _):
            appIcon.state = .off
            customB.state = .on
            macOSIconB.state = .off
            
            widthTF.isEnabled = true
            heightTF.isEnabled = true
        case .macOSIcon:
            appIcon.state = .off
            customB.state = .off
            macOSIconB.state = .on
            
            widthTF.isEnabled = false
            heightTF.isEnabled = false
        }
    }
    
}

extension ResizeViewController {
    @IBAction func tapForSelectMacOSIcon(_ sender: Any) {
        model.targetType = .macOSIcon
    }
    @IBAction func tapForSelectAppIcon(_ sender: Any) {
        model.targetType = .iOSIcon
    }
    @IBAction func tapForSelectCustom(_ sender: NSButton) {
        let width = Double(widthTF.stringValue) ?? 0
        let height = Double(heightTF.stringValue) ?? 0
        model.targetType = .custom(width: width, height: height)
    }
    
    @IBAction func tapForConvert(_ sender: Any) {
        model.convert()
    }
    @IBAction func tapForFindOriginPath(_ sender: Any) {
        openPanel(canChooseDirectories: false)
    }
    @IBAction func tapForFindTargetPath(_ sender: Any) {
        openPanel(canChooseDirectories: true)
    }
}

// MARK: - NSTextFieldDelegate
extension ResizeViewController:NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let tf = obj.object as? NSTextField else{
            return
        }
        switch tf {
        case targetImagePathTF:
            guard !tf.stringValue.isEmpty else{
                return
            }

            let fm = FileManager()
            var flag = ObjCBool(booleanLiteral: false)
            let exit = fm.fileExists(atPath: tf.stringValue, isDirectory: &flag)
            guard exit && flag.boolValue else{
                showWarning("您输入的不是文件夹或不存在")
                let r = removeFilePre(path: model.targetFolderPath?.absoluteString.removingPercentEncoding ?? "")
                targetImagePathTF.stringValue = r
                return
            }
            model.targetFolderPath = URL(fileURLWithPath: tf.stringValue)
        case widthTF:
            guard let width = Double(tf.stringValue) else{
                showWarning("您输入的宽不是数字")
                return
            }
            switch model.targetType {
            case let .custom(width: _, height: height):
                model.targetType = .custom(width: width, height: height)
            default:break
            }
        case heightTF:
            guard let height = Double(tf.stringValue) else{
                showWarning("您输入的宽不是数字")
                return
            }
            switch model.targetType {
            case let .custom(width: width, height: _):
                model.targetType = .custom(width: width, height: height)
            default:break
            }
        default:
            print("tf  : \(tf.stringValue)")
        }
    }
}

extension ResizeViewController {
    func showWarning(_ text:String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = text
        alert.runModal()
    }
    /// 打开选择文件,文件夹选择器
    func openPanel(canChooseDirectories:Bool) {
        let panel = NSOpenPanel(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100), styleMask: .fullSizeContentView, backing: .buffered, defer: true)
        panel.canChooseDirectories = canChooseDirectories
        panel.canChooseFiles = !canChooseDirectories
        panel.identifier = NSUserInterfaceItemIdentifier(rawValue: "\(canChooseDirectories)")
        panel.begin { (res) in
            guard let url = panel.url else{
                return
            }
            if canChooseDirectories {
                self.model.targetFolderPath = url
                self.targetImagePathTF.stringValue = self.removeFilePre(path: url.absoluteString.removingPercentEncoding!)
            }else{
                self.model.originImagePath = url
                self.originImagePathTF.stringValue = self.removeFilePre(path: url.absoluteString.removingPercentEncoding!)
                self.originIV.image = NSImage(contentsOf: url)
            }
        }
    }
    
    func removeFilePre(path:String) -> String {
        let fileHeader = "file://"
        guard path.hasPrefix(fileHeader) else{
            return path
        }
        let start = path.index(path.startIndex, offsetBy: fileHeader.count)
        let end   = path.endIndex
        return String(path[start ..< end])
    }
}

extension ResizeViewController {
    func addObservers() {
        model.setTargetTypeBlock = {[weak self](old,new) in
            guard let strongSelf = self else {
                return
            }
            guard old != new else{
                return
            }

            strongSelf.updateRadio(type: new)
        }
        observers = [
            model.observe(\.errorStr, options: [.new], changeHandler: { [weak self](m, change) in
                guard let strongSelf = self else{
                    return
                }
                strongSelf.errorLabel.stringValue = m.errorStr ?? ""
            })
        ]
    }
    func removeObservers() {
        for ob in observers {
            ob.invalidate()
        }
        observers = []
    }
}
