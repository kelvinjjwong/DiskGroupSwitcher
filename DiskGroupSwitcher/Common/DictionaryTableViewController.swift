//
//  DictionaryTableViewController.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2019/3/9.
//  Copyright © 2019年 nonamecat. All rights reserved.
//

import Cocoa
import LoggerFactory

class DictionaryTableViewController: NSObject {
    
    let logger = LoggerFactory.get(category: "DictionaryTableViewController")

    var checkboxes:[String:NSButton] = [:]
    var items:[[String:String]] = []
    var onClick:(([String:String]) -> Void)? = nil
    var onCheck:((String, Bool) -> Void)? = nil
    var onAction:((String) -> Void)? = nil
    var actionIcon:NSImage? = nil
    
    // MARK: CONTROLS
    
    weak var table: NSTableView!
    
    // MARK: INIT
    
    init(_ table:NSTableView) {
        self.table = table
    }
    
    func load(_ items:[[String:String]], afterLoaded:(() -> Void)? = nil) {
        lastSelectedRow = nil
        self.table.delegate = self
        self.table.dataSource = self
        self.items = items
        //self.logger.log(items.count)
        self.table.reloadData()
        
        if let afterLoaded = afterLoaded {
            self.logger.log("item amount = \(items.count) , checkbox amount = \(self.checkboxes.count)")
            afterLoaded()
        }
    }
    
    func clean(){
        self.load([[String:String]]())
    }
    
    func disableCheckboxes() {
        for (_, checkbox) in checkboxes {
            checkbox.isEnabled = false
        }
    }
    
    func enableCheckboxes() {
        for (_, checkbox) in checkboxes {
            checkbox.isEnabled = true
        }
    }
    
    func setCheckedItems(column:String, from array:[String]) {
        self.logger.log("setCheckedItems() array: \(array)")
        var indexes:[Int] = []
        for i in 0..<items.count {
            let item = items[i]
            if let columnValue = item[column] {
                //self.logger.log("checking \(columnValue)")
                if array.contains(columnValue) {
                    //self.logger.log("containes \(columnValue)")
                    indexes.append(i)
                }
            }
        }
        for (_, checkbox) in self.checkboxes {
            checkbox.state = .off
        }
        for i in indexes {
            var edititem = items[i]
            edititem["check"] = "true"
            items[i] = edititem
            if let id = edititem["id"], let checkbox = self.checkboxes["checkbox_\(id)"] {
                self.logger.log("turn \(id) on")
                checkbox.state = .on
            }
        }
    }
    
    func uncheckAll() {
        self.logger.log("uncheckAll()")
        for i in 0..<items.count {
            var item = items[i]
            item["check"] = "false"
            items[i] = item
            
            if let id = item["id"], let checkbox = self.checkboxes["checkbox_\(id)"] {
                self.logger.log("turn \(id) off")
                checkbox.state = .off
            }
        }
    }
    
    func checkAll() {
        for i in 0..<items.count {
            var item = items[i]
            item["check"] = "true"
            items[i] = item
            
            if let id = item["id"], let checkbox = self.checkboxes["checkbox_\(id)"] {
                self.logger.log("turn \(id) on")
                checkbox.state = .on
            }
        }
    }
    
    func setCheckedItems(column:String, from separatedValue:String, separator:String, quoted:Bool) {
        if separatedValue.trimmingCharacters(in: .whitespacesAndNewlines) == "" {return}
        var array:[String] = []
        let separated = separatedValue.components(separatedBy: separator)
        if quoted == true {
            for value in separated {
                let length = value.lengthOfBytes(using: .utf8)
                if length > 0 {
                    let newValue = value.replacingOccurrences(of: "\"", with: "")
                    self.logger.log("unquoted: \(newValue)")
                    array.append(newValue)
                }
            }
        }else{
            array = separated
        }
        self.setCheckedItems(column: column, from: array)
    }
    
    func getCheckedItems(column:String) -> [String] {
        var result:[String] = []
        for item in items {
            if item["check"] == "true" || item["check"] == "yes" || item["check"] == "on" {
                if let value = item[column] {
                    result.append(value)
                }
            }
        }
        return result
    }
    
    func getCheckedItemAsString(column:String, separator:String) -> String {
        let items = self.getCheckedItems(column: column)
        return items.joined(separator: separator)
    }
    
    // MARK: ACTION
    
    var lastSelectedRow:Int? {
        didSet {
            if lastSelectedRow != nil && items.count > 0 && lastSelectedRow! < items.count {
                let item = self.items[lastSelectedRow!]
                //                if self.selectionDelegate != nil {
                //                    self.selectionDelegate?.select(selectedItem)
                if self.onClick != nil {
                    self.onClick!(item)
                }
                //                }
            }
        }
    }
    
}


// MARK: TableView delegate functions

extension DictionaryTableViewController: NSTableViewDelegate {
    
    @objc @IBAction func onActionClicked(sender:NSButton) {
        let id = sender.identifier?.rawValue.replacingFirstOccurrence(of: "action_", with: "") ?? ""
        
        var index = -1
        for i in 0..<items.count {
            let item = items[i]
            if item["id"] == id {
                index = i
                break
                
            }
        }
        
        if index >= 0 {
            let edititem = items[index]
            
            self.logger.log("actioned: \(edititem)")
            self.onAction?(id)
        }
    }
    
    @objc @IBAction func onCheckboxClicked(sender:NSButton) {
        //self.logger.log("checkbox clicked \(sender.identifier?.rawValue ?? "")")
//        print(sender.identifier?.rawValue)
        let id = sender.identifier?.rawValue.replacingFirstOccurrence(of: "checkbox_", with: "") ?? ""
//        if id != "" {
            var index = -1
            for i in 0..<items.count {
                let item = items[i]
                if item["id"] == id {
                    index = i
                    break
                    
                }
            }
            if index >= 0 {
                var edititem = items[index]
                if sender.state == .on {
                    edititem["check"] = "true"
                }else{
                    edititem["check"] = "false"
                }
                items[index] = edititem
            }
            self.logger.log("checked: \(self.getCheckedItemAsString(column: "name", separator: ","))")
            if self.onCheck != nil {
                self.onCheck!(id, sender.state == .on)
            }
//        }
    }
    
    // return view for requested column.
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        if row > (self.items.count - 1) {
            return nil
        }
        let item = self.items[row]
        var value = ""
        var value_textColor = ""
        var value_backgroundColor = ""
        //var tip: String? = nil
        if let id = tableColumn?.identifier {
            var isAction = false
            var isCheckbox = false
            if id == NSUserInterfaceItemIdentifier("checkbox") {
                isCheckbox = true
            }else{
                if id == NSUserInterfaceItemIdentifier("action") {
                    isAction = true
                }else{
                    for key in item.keys {
                        if id == NSUserInterfaceItemIdentifier(key) {
                            value = item[key] ?? ""
                            
                            if let textColorKey = item.keys.first(where: { s in
                                return s == "\(key)#textColor"
                            }) {
                                value_textColor = item[textColorKey] ?? ""
                            }
                            
                            if let backgroundColorKey = item.keys.first(where: { s in
                                return s == "\(key)#backgroundColor"
                            }) {
                                value_backgroundColor = item[backgroundColorKey] ?? ""
                            }
                        }
                        
                    }
                }
            }
            let colView = tableView.makeView(withIdentifier: id, owner: nil) as! NSTableCellView
            if isCheckbox {
                colView.subviews.removeAll()
                
                let id = "checkbox_\(item["id"] ?? UUID().uuidString)"
                
                let button:NSButton = NSButton(frame: NSRect(x: 0, y: 0, width: 18, height: 18))
                button.setButtonType(NSButton.ButtonType.switch)
                button.action = #selector(DictionaryTableViewController.onCheckboxClicked(sender:))
                button.identifier = NSUserInterfaceItemIdentifier(id)
                button.target = self
                value = item["check"] ?? ""
                if value == "on" || value == "true" || value == "yes" {
                    button.state = .on
                }else{
                    button.state = .off
                }
                
                self.checkboxes[id] = button
                
                colView.addSubview(button)
            }else{
                if isAction {
                    colView.subviews.removeAll()
                    
                    let id = "action_\(item["id"] ?? UUID().uuidString)"
                    
                    let button:NSButton = NSButton(frame: NSRect(x: 0, y: 0, width: 22, height: 18))
                    button.setButtonType(.momentaryChange)
                    button.action = #selector(DictionaryTableViewController.onActionClicked(sender:))
                    button.identifier = NSUserInterfaceItemIdentifier(id)
                    button.target = self
                    if let icon = self.actionIcon {
                        button.image = icon
                        button.imagePosition = .imageOnly
                    }else{
                        button.title = "X"
                        button.imagePosition = .noImage
                    }
                    
                    colView.addSubview(button)
                }else{
                    colView.textField?.stringValue = value;
                    colView.textField?.lineBreakMode = .byClipping
                    if value_textColor != "" {
                        colView.textField?.textColor = NSColor(hex: value_textColor)
                    }
                    if value_backgroundColor != "" {
                        colView.textField?.backgroundColor = NSColor(hex: value_backgroundColor)
                    }
                    if row == tableView.selectedRow {
                        lastSelectedRow = row
                        //                    colView.textField?.textColor = NSColor.yellow
                    } else {
                        lastSelectedRow = nil
                        //                    colView.textField?.textColor = nil
                    }
                }
            }
            return colView
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        //guard let tableView = tableView as? CustomTableView else { return }
        
        //        rowView.backgroundColor = row % 2 == 1
        //            ? NSColor.gray
        //            : NSColor.darkGray
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        lastSelectedRow = row
        return true
    }
}

// MARK: TableView data source functions

extension DictionaryTableViewController: NSTableViewDataSource {
    
    /// table size is one row per image in the images array
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.items.count
    }
    
    // table sorting by column contents
    func tableView(_ tableView: NSTableView,
                   sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        // do nothing
    }
    
}
