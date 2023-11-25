//
//  DiskVolumeStackItem.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/24.
//

import Cocoa

class DiskVolumeStackItem: NSViewController {
    
    @IBOutlet weak var lblVolume: NSTextField!
    @IBOutlet weak var lblStatus: NSTextField!
    
    init() {
        super.init(nibName: "DiskVolumeStackItem", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
}

extension DiskVolumeStackItem : StackItemViewProtocol {
    
    func initView<T>(item: T, onEdit: @escaping (() -> Void), onDelete: @escaping (() -> Void), onSelect: @escaping (() -> Void)) where T: StackItemProtocol {
        print("init item view")
        self.lblVolume.stringValue = item.getName()
    }
    
}
