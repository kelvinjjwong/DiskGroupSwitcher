//
//  ViewController.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/23.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    override func viewWillAppear() {
        super.viewWillAppear()

        view.window?.styleMask.remove(.resizable)
        view.window?.styleMask.remove(.miniaturizable)
        view.window?.center()
        
//        let preferencesView = PreferencesView(frame: self.view.bounds)
//        preferencesView.add(toView: self.view)
    }


}

