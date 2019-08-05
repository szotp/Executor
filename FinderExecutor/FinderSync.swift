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
    
    var scripts: ScriptData!
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        scripts = ScriptData.load()
        let target = FIFinderSyncController.default().targetedURL()!
        let items = FIFinderSyncController.default().selectedItemURLs()
        dlog(target)
        dlog(items)
        
        let menu = NSMenu()
        
        for (i, script) in scripts.script.enumerated() {
            let subitem = menu.addItem(withTitle: script.title, action: #selector(self.executeScript), keyEquivalent: "")
            subitem.tag = i
        }
        
        menu.addItem(withTitle: "Open scripts", action: #selector(self.openScriptsDirectory), keyEquivalent: "")
        return menu
    }
    
    @objc func openScriptsDirectory() {
        CommandRunner.openScriptsDirectory()
    }
    
    @objc func executeScript(item: NSMenuItem) {
        let target = FIFinderSyncController.default().targetedURL()!
        let items = FIFinderSyncController.default().selectedItemURLs()
        let command = RunScriptCommand(currentDirectory: target, script: scripts.script[item.tag], items: items)
        CommandRunner(command: command).runInParentApp()
    }
}

