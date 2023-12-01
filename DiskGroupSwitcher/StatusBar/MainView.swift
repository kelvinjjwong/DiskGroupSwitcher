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
    
    private var selected_hostname = ""
    
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
            
            self.refreshServerList()
            cmbServer.selectItem(at: 0)
            self.reloadDiskGroups()
        }
        
    }
    
    func reloadDiskGroups() {
        
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        
        self.txtSSDName.stringValue = server.ssdGroup.name
        self.txtHDDName.stringValue = server.hddGroup.name
        
        self.loadSSDTable(data: server.getSsdDisks())
        self.loadHDDTable(data: server.getHddDisks())
        
        self.lblServerStatus.stringValue = "offline"
        self.lblServerStatus.textColor = NSColor(hex: "7F7F7F")
        
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
                    AF.request("http://\(server.hostname):\(Defaults.get.httpPort())/").validate(statusCode: 200..<300).responseString { response in
                        
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
        
        let timer6 = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block:{_ in
            if self.isOpened {
                DispatchQueue.main.async {
                    let hostname = self.cmbServer.objectValueOfSelectedItem as! String
                    if hostname != self.selected_hostname {
                        // changed
                        self.selected_hostname = hostname
                        self.reloadDiskGroups()
                    }
                }
            }
        })
        
        let timer7 = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block:{_ in
            if self.isOpened {
                DispatchQueue.main.async {
                    self.toggleSoftlinkStatus()
                }
            }
        })
        
        timer1.fire()
        timer2.fire()
        timer3.fire()
        timer4.fire()
        timer5.fire()
        timer6.fire()
        timer7.fire()
        RunLoop.current.add(timer1, forMode: .common)
        RunLoop.current.add(timer2, forMode: .common)
        RunLoop.current.add(timer3, forMode: .common)
        RunLoop.current.add(timer4, forMode: .common)
        RunLoop.current.add(timer5, forMode: .common)
        RunLoop.current.add(timer6, forMode: .common)
        RunLoop.current.add(timer7, forMode: .common)
        self.logger.log("Scheduler started.")
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
    
    func updateDiskStatus(server: Server, disk: Disk) {
        AF.request("http://\(server.hostname):\(Defaults.get.httpPort())/status/\(disk.volume)").responseString { response in
            if let responseText = response.value, let resp = MountedResponse.fromJSON(responseText) {
                Servers.stored.updateDiskStatus(hostname: server.hostname, volume: disk.volume, state: resp.mounted)
            }
        }
    }
    
    func updateSoftlinkStatus() {
        self.logger.log("Getting link status of volumes ...")
        let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
        for disk in server.ssdGroup.disks {
            self.updateSoftlinkStatus(server: server, disk: disk)
        }
        for disk in server.hddGroup.disks {
            self.updateSoftlinkStatus(server: server, disk: disk)
        }
    }
    
    func updateSoftlinkStatus(server:Server, disk: Disk){
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(["volume": disk.volume, "softlink": disk.softlink])
            if let json = String(data: jsonData, encoding: String.Encoding.utf8) {
                
                AF.request(json.post(url: "http://\(server.hostname):\(Defaults.get.httpPort())/linkstatus")).responseString { response in
                    if let responseText = response.value, let resp = LinkedResponse.fromJSON(responseText) {
                        Servers.stored.updateSoftlinkStatus(hostname: server.hostname, volume: disk.volume, state: resp.linked)
                    }
                }
            }
        }catch {}
    }
    
    func toggleSoftlinkStatus() {
        let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
        DispatchQueue.global().async {
            
            let arraySSD = server.ssdGroup.disks.map { disk in
                return disk.linked
            }
            DispatchQueue.main.async {
                self.lblSSDLinked.isHidden = arraySSD.isEmpty || arraySSD.contains(false)
                if !self.lblSSDLinked.isHidden {
                    self.btnSwitch.selectedSegment = 0
                }
            }
            
            let arrayHDD = server.hddGroup.disks.map { disk in
                return disk.linked
            }
            DispatchQueue.main.async {
                self.lblHDDLinked.isHidden = arrayHDD.isEmpty || arrayHDD.contains(false)
                if !self.lblHDDLinked.isHidden {
                    self.btnSwitch.selectedSegment = 2
                }
                
                if self.lblHDDLinked.isHidden && self.lblSSDLinked.isHidden {
                    self.btnSwitch.selectedSegment = 1
                }
            }
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
        self.txtServer.isHidden = true
        self.btnSaveServer.isHidden = true
        
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
            CLI.get.turnOn(siriComponent: self.txtSSDName.stringValue)
            
            
        }else{ // selected OFF
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
    
    // todo: change to HTTP API
    @IBAction func onSwitchClicked(_ sender: NSSegmentedControl) {
        if let label = sender.label(forSegment: sender.selectedSegment), label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || label.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("_TBC") {
            return
        }
        let server = Servers.stored.getServer(index: self.cmbServer.indexOfSelectedItem)
        struct R: Encodable {
            let volume: String
            let softlink: String
            let group: String
        }
        var array:[R] = []
        for disk in server.ssdGroup.disks {
            array.append(R(volume: disk.volume, softlink: disk.softlink, group: "ssd"))
        }
        for disk in server.hddGroup.disks {
            array.append(R(volume: disk.volume, softlink: disk.softlink, group: "hdd"))
        }
        
        if sender.selectedSegment == 0 { // selected SSD
            let jsonEncoder = JSONEncoder()
            do {
                let jsonData = try jsonEncoder.encode(array)
                if let json = String(data: jsonData, encoding: String.Encoding.utf8) {
                    
                    self.logger.log("calling http://\(server.hostname):\(Defaults.get.httpPort())/link/ssd")
                    self.logger.log(json)
                    AF.request(json.post(url: "http://\(server.hostname):\(Defaults.get.httpPort())/link/ssd")).responseString { response in
                        if let responseText = response.value, let resp = GenericResponse.fromJSON(responseText) {
                            print(resp)
                        }
                    }
                }
            }catch{}
        }else if sender.selectedSegment == 1 { // selected none
            
            let jsonEncoder = JSONEncoder()
            do {
                let jsonData = try jsonEncoder.encode(array)
                if let json = String(data: jsonData, encoding: String.Encoding.utf8) {
                    
                    self.logger.log("calling http://\(server.hostname):\(Defaults.get.httpPort())/unlink/all")
                    self.logger.log(json)
                    AF.request(json.post(url: "http://\(server.hostname):\(Defaults.get.httpPort())/unlink/all")).responseString { response in
                        if let responseText = response.value, let resp = GenericResponse.fromJSON(responseText) {
                            print(resp)
                        }
                    }
                }
            }catch{}
            
        }else if sender.selectedSegment == 2 { // selected HDD
            
            let jsonEncoder = JSONEncoder()
            do {
                let jsonData = try jsonEncoder.encode(array)
                if let json = String(data: jsonData, encoding: String.Encoding.utf8) {
                    
                    self.logger.log("calling http://\(server.hostname):\(Defaults.get.httpPort())/link/hdd")
                    self.logger.log(json)
                    AF.request(json.post(url: "http://\(server.hostname):\(Defaults.get.httpPort())/link/hdd")).responseString { response in
                        if let responseText = response.value, let resp = GenericResponse.fromJSON(responseText) {
                            print(resp)
                        }
                    }
                }
            }catch{}
            
        }
    }
    
    @IBAction func onAddSSDClicked(_ sender: NSButton) {
        let volume = self.txtSSDVolumeName.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let softlink = self.txtSSDLink.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard volume != "" else {return}
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        Servers.stored.addSsdDisk(hostname: server.hostname, volume: volume, link: softlink)
        
        AF.request("http://\(server.hostname):\(Defaults.get.httpPort())/status/\(volume)").responseString { response in
            if let responseText = response.value, let resp = MountedResponse.fromJSON(responseText) {
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
            if let responseText = response.value, let resp = MountedResponse.fromJSON(responseText) {
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
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        self.txtServer.isHidden = false
        self.txtServer.isEditable = true
        self.txtServer.isBordered = true
        self.txtServer.stringValue = "xxxx.local"
        self.txtServer.textColor = NSColor(hex: "FFFFFF")
        self.txtServer.backgroundColor = NSColor(hex: "222222")
        self.btnSaveServer.isHidden = false
    }
    
    @IBAction func onRemoveServerClicked(_ sender: NSButton) {
        let server = Servers.stored.getServer(index: cmbServer.indexOfSelectedItem)
        self.txtServer.isBordered = false
        self.txtServer.isHidden = false
        self.txtServer.isEditable = false
        self.txtServer.stringValue = "Confirm DELETE \(server.hostname) ?"
        self.txtServer.textColor = NSColor(hex: "FF0000")
        self.txtServer.backgroundColor = NSColor(hex: "222222")
        self.btnSaveServer.isHidden = false
    }
    
    func refreshServerList() {
        self.lblServerStatus.stringValue = "offline"
        self.lblServerStatus.textColor = NSColor(hex: "7F7F7F")
        cmbServer.removeAllItems()
        for hostname in Servers.stored.hostnames() {
            // add hostname to combobox
            cmbServer.addItem(withObjectValue: hostname)
        }
    }
    
    @IBAction func onSaveServerClicked(_ sender: NSButton) {
        let server_hostname = self.txtServer.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.txtServer.isEditable {
            Servers.stored.addServer(hostname: server_hostname, ssdGroupName: "SSD_TBC", hddGroupName: "HDD_TBC")
            
            self.refreshServerList()
            cmbServer.selectItem(withObjectValue: server_hostname)
            self.reloadDiskGroups()
        }else{
            Servers.stored.removeServer(hostname: server_hostname)
            
            self.refreshServerList()
            cmbServer.selectItem(at: 0)
            self.reloadDiskGroups()
        }
        self.txtServer.isHidden = true
        self.btnSaveServer.isHidden = true
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
