//
//  MainView.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/23.
//

import Cocoa
import LoggerFactory
import Alamofire

class MainView: NSView, LoadableView {
    
    let logger = LoggerFactory.get(category: "UI", subCategory: "MainView")
    
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
    @IBOutlet weak var txtSSDLink: NSTextField!
    @IBOutlet weak var txtHDDLink: NSTextField!
    @IBOutlet weak var btnAddServer: NSButton!
    @IBOutlet weak var btnRemoveServer: NSButton!
    @IBOutlet weak var btnSaveServer: NSButton!
    @IBOutlet weak var lblSSDLinked: NSTextField!
    @IBOutlet weak var lblHDDLinked: NSTextField!
    @IBOutlet weak var txtServer: NSTextField!
    
    @IBOutlet weak var tblSSD: NSTableView!
    @IBOutlet weak var tblHDD: NSTableView!
    
    var ssdTableController : DictionaryTableViewController!
    var hddTableController : DictionaryTableViewController!
    
    // MARK: - Init
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _ = load(fromNIBNamed: "MainView")
        self.lblSSDLinked.isHidden = true
        self.lblHDDLinked.isHidden = true
        self.txtServer.isHidden = true
        self.btnSaveServer.isHidden = true
        
        self.initData()
        self.startScheduler()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var isOpened = false
    
    func initData() {
        
        if Servers.stored.count() == 0 {
            _ = Servers.stored.loadServers()
            Servers.stored.cleanAllStatus()
        
            if Servers.stored.count() == 0 {
                self.prepareStubServers()
            }
        }
    }
    
    var inited = false
    
    func initUI() {
        if !self.inited {
            
            self.inited = true
            
            cmbServer.removeAllItems()
            for hostname in Servers.stored.hostnames() {
                // add hostname to combobox
                cmbServer.addItem(withObjectValue: hostname)
            }
            cmbServer.selectItem(at: 0)
            
            let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
            
            self.txtSSDName.stringValue = server.ssdGroup.name
            self.txtHDDName.stringValue = server.hddGroup.name
            
            self.loadSSDTable(data: server.getSsdDisks())
            self.loadHDDTable(data: server.getHddDisks())
            
            self.lblMessage.stringValue = "online"
            
        }
        
    }
    
    func startScheduler() {
        let timer1 = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block:{_ in
            if self.isOpened {
                DispatchQueue.main.async {
                    self.updateDiskStatus()
                }
            }
        })
        let timer2 = Timer.scheduledTimer(withTimeInterval: 6, repeats: true, block:{_ in
            if self.isOpened {
                DispatchQueue.main.async {
                    self.refreshTables()
                }
            }
        })
        
        let timer3 = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block:{_ in
            if self.isOpened {
                DispatchQueue.main.async {
                    let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
                    self.btnToggleSSD.selectedSegment = server.ssdGroup.isOnline() ? 0 : 1
                    self.btnToggleHDD.selectedSegment = server.hddGroup.isOnline() ? 0 : 1
                }
            }
        })
        
        let timer4 = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block:{_ in
            if self.isOpened {
                DispatchQueue.main.async {
                    let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
                    AF.request("http://\(server.hostname):\(Defaults.get.httpPort())/").responseString { response in
                        if let responseText = response.value, let _ = HealthCheck.fromJSON(responseText) {
                            self.lblServerStatus.stringValue = "online"
                            self.lblServerStatus.textColor = NSColor(hex: "00FF00")
                        }else{
                            self.lblServerStatus.stringValue = "offline"
                            self.lblServerStatus.textColor = NSColor(hex: "7F7F7F")
                        }
                    }
                }
            }
        })
        
        let timer5 = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block:{_ in
            if self.isOpened {
                DispatchQueue.main.async {
                    self.updateSoftlinkStatus()
                }
            }
        })
        
        timer1.fire()
        timer2.fire()
        timer3.fire()
        timer4.fire()
        timer5.fire()
        RunLoop.current.add(timer1, forMode: .common)
        RunLoop.current.add(timer2, forMode: .common)
        RunLoop.current.add(timer3, forMode: .common)
        RunLoop.current.add(timer4, forMode: .common)
        RunLoop.current.add(timer5, forMode: .common)
        self.logger.log("Scheduler started.")
    }
    
    func updateDiskStatus(server: Server, disk: Disk) {
        AF.request("http://\(server.hostname):\(Defaults.get.httpPort())/status/\(disk.volume)").responseString { response in
            if let responseText = response.value, let resp = HTTPResponse.fromJSON(responseText) {
                Servers.stored.updateDiskStatus(hostname: server.hostname, volume: disk.volume, state: resp.mounted)
            }
        }
    }
    
    func updateSoftlinkStatus() {
        let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
        DispatchQueue.global().async {
            
            let arraySSD = server.ssdGroup.disks.map { disk in
                return disk.isLinked()
            }
            DispatchQueue.main.async {
                self.lblSSDLinked.isHidden = arraySSD.contains(false)
                if !self.lblSSDLinked.isHidden {
                    self.btnSwitch.selectedSegment = 0
                }
            }
            
            let arrayHDD = server.hddGroup.disks.map { disk in
                return disk.isLinked()
            }
            DispatchQueue.main.async {
                self.lblHDDLinked.isHidden = arrayHDD.contains(false)
                if !self.lblHDDLinked.isHidden {
                    self.btnSwitch.selectedSegment = 2
                }
                
                if self.lblHDDLinked.isHidden && self.lblSSDLinked.isHidden {
                    self.btnSwitch.selectedSegment = 1
                }
            }
        }
        
    }
    
    func updateDiskStatus() {
        self.logger.log("Getting status of volumes ...")
        let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
        for disk in server.ssdGroup.disks {
            self.updateDiskStatus(server: server, disk: disk)
        }
        for disk in server.hddGroup.disks {
            self.updateDiskStatus(server: server, disk: disk)
        }
    }
    
    func refreshTables() {
        self.logger.log("Refreshing tables ...")
        let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
        self.ssdTableController.load(server.getSsdDisks())
        self.hddTableController.load(server.getHddDisks())
    }
    
    func loadSSDTable(data:[[String:String]]) {
        
        self.ssdTableController = DictionaryTableViewController(self.tblSSD)
        self.ssdTableController.actionIcon = NSImage(named: "NSMenuMixedStateTemplate")
        self.ssdTableController.onClick = { row in
            let volume = row["volume"]
            let link = row["softlink"]
            self.txtSSDVolumeName.stringValue = volume?.components(separatedBy: "/")[2] ?? ""
            self.txtSSDLink.stringValue = link ?? ""
        }
        self.ssdTableController.onAction = { id in
            
            // do nothing
        }
        self.ssdTableController.load(data, afterLoaded: {
        })
    }
    
    func loadHDDTable(data:[[String:String]]) {
        
        self.hddTableController = DictionaryTableViewController(self.tblHDD)
        self.hddTableController.actionIcon = NSImage(named: "NSMenuMixedStateTemplate")
        self.hddTableController.onClick = { row in
            let volume = row["volume"]
            let link = row["softlink"]
            self.txtHDDVolumeName.stringValue = volume?.components(separatedBy: "/")[2] ?? ""
            self.txtHDDLink.stringValue = link ?? ""
        }
        self.hddTableController.onAction = { id in
            
            // do nothing
        }
        self.hddTableController.load(data, afterLoaded: {
        })
    }
    
    func onOpen() {
        self.isOpened = true
        self.logger.log(.trace, "menu open")
        DispatchQueue.main.async {
            self.initUI()
            self.updateDiskStatus()
            self.refreshTables()
        }
    }
    
    func onClose() {
        self.isOpened = false
        self.logger.log(.trace, "menu close")
        
    }
    
    @IBAction func onEditSSDNameClicked(_ sender: NSButton) {
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        Servers.stored.updateSsdGroupName(hostname: server.hostname, ssdGroupName: self.txtSSDName.stringValue)
        
    }
    
    @IBAction func onEditHDDNameClicked(_ sender: NSButton) {
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        Servers.stored.updateHddGroupName(hostname: server.hostname, hddGroupName: self.txtHDDName.stringValue)
    }
    
    @IBAction func onToggleSSDClicked(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 { // selected ON
            print(0)
            CLI.get.turnOn(siriComponent: self.txtSSDName.stringValue)
            
            
        }else{ // selected OFF
            print(1)
            let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
            let siriComponent = self.txtSSDName.stringValue
            DispatchQueue.global().async {
                let volumes = server.ssdGroup.volumes()
                _ = CLI.get.umount(volumes: volumes)
                var n = volumes.count
                while(n > 0){
                    let lines = CLI.get.listmount(volumes: volumes)
                    n = lines.count
                }
                CLI.get.turnOff(siriComponent: siriComponent)
            }
        }
    }
    
    @IBAction func onToggleHDDClicked(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 { // selected ON
            CLI.get.turnOn(siriComponent: self.txtHDDName.stringValue)
        }else{ // selected OFF
            let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
            let siriComponent = self.txtHDDName.stringValue
            DispatchQueue.global().async {
                let volumes = server.hddGroup.volumes()
                _ = CLI.get.umount(volumes: volumes)
                var n = volumes.count
                let startTime = Date()
                while(n > 0){
                    let now = Date()
                    if now.timeIntervalSince(startTime) > 3 {
                        break
                    }
                    let lines = CLI.get.listmount(volumes: volumes)
                    n = lines.count
                }
                CLI.get.turnOff(siriComponent: siriComponent)
            }
        }
    }
    
    @IBAction func onSwitchClicked(_ sender: NSSegmentedControl) {
        let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
        if sender.selectedSegment == 0 { // selected SSD
            for disk in server.hddGroup.disks {
                disk.unlink()
            }
            for disk in server.ssdGroup.disks {
                disk.unlink()
            }
            for disk in server.ssdGroup.disks {
                disk.link()
            }
        }else if sender.selectedSegment == 1 { // selected none
            for disk in server.hddGroup.disks {
                disk.unlink()
            }
            for disk in server.ssdGroup.disks {
                disk.unlink()
            }
            
        }else if sender.selectedSegment == 2 { // selected HDD
            for disk in server.hddGroup.disks {
                disk.unlink()
            }
            for disk in server.ssdGroup.disks {
                disk.unlink()
            }
            for disk in server.hddGroup.disks {
                disk.link()
            }
            
        }
    }
    
    @IBAction func onAddSSDClicked(_ sender: NSButton) {
        let volume = self.txtSSDVolumeName.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let softlink = self.txtSSDLink.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard volume != "" else {return}
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        Servers.stored.addSsdDisk(hostname: server.hostname, volume: volume, link: softlink)
        
        AF.request("http://\(server.hostname):\(Defaults.get.httpPort())/status/\(volume)").responseString { response in
            if let responseText = response.value, let resp = HTTPResponse.fromJSON(responseText) {
                Servers.stored.updateDiskStatus(hostname: server.hostname, volume: volume, state: resp.mounted)
                self.ssdTableController.load(server.getSsdDisks())
            }
        }
        self.ssdTableController.load(server.getSsdDisks())
    }
    
    @IBAction func onAddHDDClicked(_ sender: NSButton) {
        let volume = self.txtHDDVolumeName.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let softlink = self.txtHDDLink.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard volume != "" else {return}
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        Servers.stored.addHddDisk(hostname: server.hostname, volume: volume, link: softlink)
        AF.request("http://\(server.hostname):\(Defaults.get.httpPort())/status/\(volume)").responseString { response in
            if let responseText = response.value, let resp = HTTPResponse.fromJSON(responseText) {
                Servers.stored.updateDiskStatus(hostname: server.hostname, volume: volume, state: resp.mounted)
                self.hddTableController.load(server.getHddDisks())
            }
        }
        self.hddTableController.load(server.getHddDisks())
    }
    
    @IBAction func onRemoveSSDClicked(_ sender: NSButton) {
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        Servers.stored.removeSsdDisk(hostname: server.hostname, volume: self.txtSSDVolumeName.stringValue)
        self.loadSSDTable(data: server.getSsdDisks())
    }
    
    @IBAction func onRemoveHDDClicked(_ sender: NSButton) {
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        Servers.stored.removeHddDisk(hostname: server.hostname, volume: self.txtHDDVolumeName.stringValue)
        self.loadHDDTable(data: server.getHddDisks())
    }
    
    @IBAction func onAddServerClicked(_ sender: NSButton) {
    }
    
    @IBAction func onRemoveServerClicked(_ sender: NSButton) {
    }
    
    @IBAction func onSaveServerClicked(_ sender: NSButton) {
    }
    
    func prepareStubServers() {
        
        let server1 = Server(hostname: "kelvinstation.local",
                             ssd: DiskGroup(name: "Station Fast", disks: [
                                Disk(volume: "FastPhoto1", link: "/Users/plex/photo1"),
                                Disk(volume: "FastPhoto2", link: "/Users/plex/photo2"),
                                Disk(volume: "FastPhoto3", link: "/Users/plex/photo3")
                             ]),
                             hdd: DiskGroup(name: "Station HDD", disks: [
                                Disk(volume: "Photo1", link: "/Users/plex/photo1"),
                                Disk(volume: "Photo2", link: "/Users/plex/photo2"),
                                Disk(volume: "Photo3", link: "/Users/plex/photo3")
                             ]))
        
        
        let server2 = Server(hostname: "photostation.local",
                             ssd: DiskGroup(name: "Photo Fast", disks: [
                                Disk(volume: "ImageStorageFast")
                             ]),
                             hdd: DiskGroup(name: "Photo HDD", disks: [
                                Disk(volume: "ImageStorage")
                             ]))
        
        Servers.stored.addServer(server1)
        Servers.stored.addServer(server2)
    }
    
}
