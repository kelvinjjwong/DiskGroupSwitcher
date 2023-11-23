//
//  MainView.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/23.
//

import Cocoa

class MainView: NSView, LoadableView {
    
    @IBOutlet weak var lblMessage: NSTextField!
    
    
    // MARK: - Init
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _ = load(fromNIBNamed: "MainView")
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func onOpen() {
        print("menu open")
        self.lblMessage.stringValue = "online"
    }
    
    func onClose() {
        print("menu close")
        
    }
}
