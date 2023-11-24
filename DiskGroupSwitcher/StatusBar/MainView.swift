//
//  MainView.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/23.
//

import Cocoa

class MainView: NSView, LoadableView {
    
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var cmbServer: NSComboBox!
    @IBOutlet weak var lblServerStatus: NSTextField!
    @IBOutlet weak var btnSwitch: NSSegmentedControl!
    @IBOutlet weak var txtSSDName: NSTextField!
    @IBOutlet weak var btnEditSSDName: NSButton!
    @IBOutlet weak var btnToggleSSD: NSSegmentedControl!
    @IBOutlet weak var txtHDDName: NSTextField!
    @IBOutlet weak var btnEditHDDName: NSButton!
    @IBOutlet weak var btnToggleHDD: NSSegmentedControl!
    @IBOutlet weak var stackSSD: CustomStackView!
    @IBOutlet weak var stackHDD: CustomStackView!
    @IBOutlet weak var txtSSDVolumeName: NSTextField!
    @IBOutlet weak var btnAddSSDVolume: NSButton!
    @IBOutlet weak var txtHDDVolumeName: NSTextField!
    @IBOutlet weak var btnAddHDDVolume: NSButton!
    
    
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
    
    @IBAction func onEditSSDNameClicked(_ sender: NSButton) {
    }
    
    @IBAction func onEditHDDNameClicked(_ sender: NSButton) {
    }
    
    @IBAction func onToggleSSDClicked(_ sender: NSSegmentedControl) {
    }
    
    @IBAction func onToggleHDDClicked(_ sender: NSSegmentedControl) {
    }
    
    @IBAction func onSwitchClicked(_ sender: NSSegmentedControl) {
    }
    
    @IBAction func onAddSSDClicked(_ sender: NSButton) {
    }
    
    @IBAction func onAddHDDClicked(_ sender: NSButton) {
    }
    
}
