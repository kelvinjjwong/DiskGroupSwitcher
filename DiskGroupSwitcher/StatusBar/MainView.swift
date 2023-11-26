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
    @IBOutlet weak var txtSSDVolumeName: NSTextField!
    @IBOutlet weak var btnAddSSDVolume: NSButton!
    @IBOutlet weak var txtHDDVolumeName: NSTextField!
    @IBOutlet weak var btnAddHDDVolume: NSButton!
    @IBOutlet weak var btnRemoveSSDVolume: NSButton!
    @IBOutlet weak var btnRemoveHDDVolume: NSButton!
    
    @IBOutlet weak var tblSSD: NSTableView!
    @IBOutlet weak var tblHDD: NSTableView!
    
    var ssdTableController : DictionaryTableViewController!
    var hddTableController : DictionaryTableViewController!
    
    
    private var servers:[Server] = []
    
    // MARK: - Init
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _ = load(fromNIBNamed: "MainView")
        self.wantsLayer = true
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func loadSSDTable(data:[[String:String]]) {
        
        self.ssdTableController = DictionaryTableViewController(self.tblSSD)
        self.ssdTableController.actionIcon = NSImage(named: "NSMenuMixedStateTemplate")
        self.ssdTableController.onAction = { id in
            
            // do nothing
        }
        self.ssdTableController.load(data, afterLoaded: {
        })
    }
    
    func loadHDDTable(data:[[String:String]]) {
        
        self.hddTableController = DictionaryTableViewController(self.tblHDD)
        self.hddTableController.actionIcon = NSImage(named: "NSMenuMixedStateTemplate")
        self.hddTableController.onAction = { id in
            
            // do nothing
        }
        self.hddTableController.load(data, afterLoaded: {
        })
    }
    
    func onOpen() {
        print("menu open")
        self.lblMessage.stringValue = "online"
        if self.servers.count == 0 {
            self.servers = Servers.stored.loadServers()
            Servers.stored.cleanAllStatus()
        
            if servers.count == 0 {
                let server1 = Server(hostname: "kelvinstation.local",
                                     ssd: DiskGroup(name: "Station Fast", disks: [
                                        Disk(volume: "FastPhoto1"),
                                        Disk(volume: "FastPhoto2"),
                                        Disk(volume: "FastPhoto3"),
                                        Disk(volume: "FastPhoto4"),
                                        Disk(volume: "FastPhoto5"),
                                        Disk(volume: "FastPhoto6"),
                                        Disk(volume: "FastPhoto7")
                                     ]),
                                     hdd: DiskGroup(name: "Station HDD", disks: [
                                        Disk(volume: "Photo1"),
                                        Disk(volume: "Photo2"),
                                        Disk(volume: "Photo3"),
                                        Disk(volume: "Photo4"),
                                        Disk(volume: "Photo5"),
                                        Disk(volume: "Photo6"),
                                        Disk(volume: "Photo7")
                                     ]))
                
                
                let server2 = Server(hostname: "photostation.local",
                                     ssd: DiskGroup(name: "Photo Fast", disks: [
                                        Disk(volume: "ImageStorageFast")
                                     ]),
                                     hdd: DiskGroup(name: "Photo HDD", disks: [
                                        Disk(volume: "ImageStorage")
                                     ]))
                
                servers.append(server1)
                servers.append(server2)
            }
        }
        
        cmbServer.removeAllItems()
        for server in servers {
            // add hostname to combobox
            cmbServer.addItem(withObjectValue: server.hostname)
        }
        cmbServer.selectItem(at: 0)
        
        let server = servers[0]
        
        var ssdVolumes:[[String:String]] = []
        for disk in server.ssdGroup.disks {
            var volume:[String:String] = [:]
            volume["volume"] = disk.getName()
            volume["status"] = disk.online ? "online" : "offline"
            volume["status#textColor"] = disk.online ? "00FF00" : "7F7F7F"
            ssdVolumes.append(volume)
        }
        
        self.loadSSDTable(data: ssdVolumes)
        
        var hddVolumes:[[String:String]] = []
        for disk in server.hddGroup.disks {
            var volume:[String:String] = [:]
            volume["volume"] = disk.getName()
            volume["status"] = disk.online ? "online" : "offline"
            volume["status#textColor"] = disk.online ? "00FF00" : "7F7F7F"
            hddVolumes.append(volume)
        }
        
        self.loadHDDTable(data: hddVolumes)
        
        print(NSColor(named: "gray"))
        
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
    
    @IBAction func onRemoveSSDClicked(_ sender: NSButton) {
    }
    
    @IBAction func onRemoveHDDClicked(_ sender: NSButton) {
    }
    
}
