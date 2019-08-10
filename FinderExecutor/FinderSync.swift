//
//  FinderSync.swift
//  FinderExecutor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa
import FinderSync
import ExecutorKit

class FinderSync: FIFinderSync {

    var myFolderURL = URL(fileURLWithPath: "/")
    
    override init() {
        super.init()
        
        dlog("init")
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    
    var scripts = ScriptDataLoader()
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let time = Date()
        defer {
            dlog("\(#function) took \(-time.timeIntervalSinceNow * 1000)ms")
        }
        
        let target = FIFinderSyncController.default().targetedURL()!
        let items = FIFinderSyncController.default().selectedItemURLs() ?? []
        
        let menu = NSMenu()
        
        
        let command = ScriptContext(currentDirectory: target, items: items)
        for (i, script) in scripts.value.script.enumerated() {
            if !script.triggers.canRun(command: command) {
                continue
            }
            
            let subitem = menu.addItem(withTitle: script.title, action: #selector(self.executeScript), keyEquivalent: "")
            subitem.tag = i
        }
        
        menu.addItem(withTitle: "Open scripts", action: #selector(self.openScriptsDirectory), keyEquivalent: "")
        return menu
    }
    
    @objc  func openScriptsDirectory() {
        CommandRunner.openScriptsDirectory()
    }
    
    @objc func executeScript(item: NSMenuItem) {
        let target = FIFinderSyncController.default().targetedURL()!
        let items = FIFinderSyncController.default().selectedItemURLs() ?? []
        let command = ScriptContext(currentDirectory: target, items: items)
        CommandRunner(command: command, script: scripts.value.script[item.tag]).runInParentApp()
    }
}

