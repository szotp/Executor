//
//  FinderSync.swift
//  FinderExecutor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    var myFolderURL = URL(fileURLWithPath: "/")
    
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    
    var scripts: [ScriptInfo] = []
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu()
        let item = menu.addItem(withTitle: "Executor", action: nil, keyEquivalent: "")
        item.submenu = NSMenu()
        
        scripts = ScriptInfo.load()
        for (i, script) in scripts.enumerated() {
            let subitem = item.submenu!.addItem(withTitle: script.title, action: #selector(executeScript), keyEquivalent: "")
            subitem.tag = i
        }
        
        item.submenu!.addItem(withTitle: "Open scripts", action: #selector(openScriptsDirectory), keyEquivalent: "")
        
        return menu
    }
    
    @objc func openScriptsDirectory() {
        RunScriptCommand.openScriptsDirectory()
    }
    
    @objc func executeScript(item: NSMenuItem) {
        let target = FIFinderSyncController.default().targetedURL()!
        let items = FIFinderSyncController.default().selectedItemURLs()
        let scriptWithInput = RunScriptCommand(currentDirectory: target, script: scripts[item.tag], items: items)
        
        scriptWithInput.sendToParent()
    }
}

