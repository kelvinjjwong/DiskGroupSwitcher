//
//  AppDelegate.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/23.
//

import Cocoa
import LoggerFactory
import Criollo

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var menu: NSMenu?
    @IBOutlet weak var firstMenuItem: NSMenuItem?
    
    var statusItem: NSStatusItem?
    var mainView: MainView?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        LoggerFactory.append(logWriter: ConsoleLogger())
        LoggerFactory.append(logWriter: FileLogger())
        LoggerFactory.enable([.info, .error, .warning, .trace, .debug])
        HTTPServer.default.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        HTTPServer.default.stop()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // statusItem?.button?.title = "WorldTime"
        
        let itemImage = NSImage(named: "disk")
        itemImage?.isTemplate = true
        statusItem?.button?.image = itemImage
        
        if let menu = menu {
            statusItem?.menu = menu
            menu.delegate = self
        }
        
        if let item = firstMenuItem {
            mainView = MainView(frame: NSRect(x: 0.0, y: 0.0, width: 500.0, height: 450.0))
            item.view = mainView
        }
    }


}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        mainView?.onOpen()
    }
    
    
    func menuDidClose(_ menu: NSMenu) {
        mainView?.onClose()
    }
}

