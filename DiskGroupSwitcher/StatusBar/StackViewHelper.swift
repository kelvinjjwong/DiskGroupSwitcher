//
//  StackViewHelper.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/11/25.
//

import Cocoa

public protocol StackItemProtocol {
    func getId() -> String
    func getName() -> String
}

public protocol StackItemViewProtocol : NSViewController {
    
    func initView<T>(item:T,
                        onEdit:@escaping (() -> Void),
                        onDelete:@escaping (() -> Void),
                        onSelect:@escaping (() -> Void)) where T: StackItemProtocol
}

public class StackViewHelper<S,T> where S:StackItemProtocol, T : StackItemViewProtocol {
    
    var stackItemStoryboardId:String
    
    var stackItems:[String:T] = [:]
    var stack: CustomStackView
    
    public init(stackItemStoryboardId: String, stack: CustomStackView) {
        self.stackItemStoryboardId = stackItemStoryboardId
        self.stack = stack
        self.stack.wantsLayer = true
        self.stack.setHuggingPriority(NSLayoutConstraint.Priority.defaultHigh, for: .horizontal)
    }
    
    func addStackItem(item: S,
                      onEdit:@escaping (() -> Void),
                      onDelete:@escaping (() -> Void),
                      onSelect:@escaping (() -> Void)) -> Bool {
        if let _ = stackItems[item.getId()] {
            return false
        }
        
        let storyboard = NSStoryboard(name: self.stackItemStoryboardId, bundle: nil)
        let stackItem = storyboard.instantiateController(withIdentifier: self.stackItemStoryboardId) as! T
        
        stack.addArrangedSubview(stackItem.view)
        print(stackItem.isViewLoaded)
        
        stackItem.initView(item: item, onEdit: onEdit, onDelete: {
            self.deleteStackItem(item: item)
            onDelete()
        }, onSelect: onSelect)
        print(stackItem.isViewLoaded)
        
        stackItems[item.getId()] = stackItem
        
        
        return true
        
    }
    
    func deleteStackItem(item: S) {
        
        for (id, stackItem) in stackItems {
            if id == item.getId(){
                stack.removeConstraints(stackItem.view.constraints)
                stack.removeView(stackItem.view)
            }
        }
        stackItems.removeValue(forKey: item.getId())
    }
}
