//
//  InputManager.swift
//  DiskGroupSwitcher
//
//  Created by kelvinwong on 2023/12/7.
//

import Carbon
import Cocoa
import Foundation
import LoggerFactory

class InputSource: Equatable {
    static func == (lhs: InputSource, rhs: InputSource) -> Bool {
        return lhs.id == rhs.id
    }

    let tisInputSource: TISInputSource

    var id: String {
        return tisInputSource.id
    }

    var name: String {
        return tisInputSource.name
    }

    var isCJKV: Bool {
        if let lang = tisInputSource.sourceLanguages.first {
            return lang == "ko" || lang == "ja" || lang == "vi"
            || lang.hasPrefix("zh")
        }
        return false
    }

    init(tisInputSource: TISInputSource) {
        self.tisInputSource = tisInputSource
    }

    func select() {
        let currentSource = InputSourceManager.getCurrentSource()
        if currentSource.id == self.id {
            return
        }
        TISSelectInputSource(tisInputSource)
        if self.isCJKV {
            if let nonCJKV = InputSourceManager.nonCJKVSource() {
                TISSelectInputSource(nonCJKV.tisInputSource)
                InputSourceManager.selectPrevious()
            }
        }
    }
}

class InputSourceManager {
    static var inputSources: [InputSource] = []
    static var uSeconds: UInt32 = 20000
    static var keyboardOnly: Bool = true

    static func initialize() {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false)
            .takeRetainedValue() as NSArray
        var inputSourceList = inputSourceNSArray as! [TISInputSource]
        if self.keyboardOnly {
            inputSourceList = inputSourceList.filter(
                {
                    $0.category == TISInputSource.Category.keyboardInputSource
                })
        }

        inputSources = inputSourceList.filter(
            {
                $0.isSelectable
            }).map { InputSource(tisInputSource: $0) }
    }

    static func nonCJKVSource() -> InputSource? {
        return inputSources.first(where: { !$0.isCJKV })
    }

    static func getCurrentSource()->InputSource{
        return InputSource(
            tisInputSource:
            TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        )
    }

    static func getInputSource(name: String)->InputSource?{
        let inputSources = InputSourceManager.inputSources
        return inputSources.filter({$0.id == name}).first
    }

    static func selectPrevious(){
        let shortcut = getSelectPreviousShortcut()
        if (shortcut == nil){
            print("""
                  Shortcut to select previous input source does not exit,
                  please read README of macism
                  """)
            exit(1)
        }
        let src = CGEventSource(stateID: .hidSystemState)

        let key = CGKeyCode(shortcut!.0)
        let flag = CGEventFlags(rawValue: shortcut!.1)

        let down = CGEvent(keyboardEventSource: src,
                           virtualKey: key, keyDown: true)!
        down.flags = flag;
        down.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: src,
                         virtualKey: key, keyDown: false)!
        // if with flag, a pop up will show up
        // up.flags = flag;
        up.post(tap: .cghidEventTap)
        usleep(InputSourceManager.uSeconds)
    }

    // from read-symbolichotkeys script of Karabiner
    // github.com/tekezo/Karabiner/blob/master/src/util/read-symbolichotkeys/read-symbolichotkeys/main.m
    static func getSelectPreviousShortcut() -> (Int, UInt64)? {
        guard let dict = UserDefaults.standard.persistentDomain(
            forName: "com.apple.symbolichotkeys"
        )
        else {
            return nil
        }
        guard let symbolichotkeys = dict["AppleSymbolicHotKeys"]
        as! NSDictionary?
        else {
            return nil
        }
        guard let symbolichotkey = symbolichotkeys["60"] as! NSDictionary?
        else {
            return nil
        }
        if (symbolichotkey["enabled"] as! NSNumber).intValue != 1 {
            return nil
        }
        guard let value = symbolichotkey["value"] as! NSDictionary? else {
            return nil
        }
        guard let parameters = value["parameters"] as! NSArray? else {
            return nil
        }
        return (
            (parameters[1] as! NSNumber).intValue,
            (parameters[2] as! NSNumber).uint64Value
        )
    }
}

extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            return kTISCategoryKeyboardInputSource as String
        }
    }

    private func getProperty(_ key: CFString) -> AnyObject? {
        let cfType = TISGetInputSourceProperty(self, key)
        if (cfType != nil) {
            return Unmanaged<AnyObject>.fromOpaque(cfType!)
            .takeUnretainedValue()
        } else {
            return nil
        }
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var name: String {
        return getProperty(kTISPropertyLocalizedName) as! String
    }

    var category: String {
        return getProperty(kTISPropertyInputSourceCategory) as! String
    }

    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }
}

public class InputManager {
    
    static let logger = LoggerFactory.get(category: "InputManager")
    
    private init() {}
    
    public static func select(_ name:String) {
        InputSourceManager.initialize()
        InputSourceManager.keyboardOnly = true
        let dstSource = InputSourceManager.getInputSource(name: name)

        if (dstSource == nil){
            InputManager.logger.log(.error, "Input source \(name) does not exist!")
        }
        dstSource?.select()
    }
}
