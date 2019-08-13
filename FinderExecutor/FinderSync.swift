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
    var current: ScriptData!
    
    func makeMenu(from folder: ScriptFolder, context: ScriptContext) -> NSMenu {
        let menu = NSMenu()
        dlog(folder.name)
        
        for subfolder in folder.subfolders {
            let submenu = self.makeMenu(from: subfolder, context: context)
            submenu.title = subfolder.name
            
            if submenu.items.count > 0 {
                let subitem = menu.addItem(withTitle: subfolder.name, action: nil, keyEquivalent: "")
                subitem.submenu = submenu
            }
        }
        
        for script in folder.items {
            if !script.triggers.canRun(command: context) {
                continue
            }
            
            let subitem = NSMenuItem(title: script.title, action: #selector(self.executeScript), keyEquivalent: "")
            subitem.tag = script.tag
            menu.addItem(subitem)
        }
        return menu
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        current = scripts.value
        
        let time = Date()
        defer {
            dlog("took \(-time.timeIntervalSinceNow * 1000)ms")
        }
        
        let target = FIFinderSyncController.default().targetedURL()!
        let items = FIFinderSyncController.default().selectedItemURLs() ?? []
        let command = ScriptContext(currentDirectory: target, items: items)

        let menu = self.makeMenu(from: current.root, context: command)
        menu.addItem(withTitle: "Open scripts", action: #selector(self.openScriptsDirectory), keyEquivalent: "")
        
        dlog("done")
        return menu
    }
    
    @objc  func openScriptsDirectory() {
        CommandRunner.openScriptsDirectory()
    }
    
    @objc func executeScript(item: NSMenuItem) {
        let target = FIFinderSyncController.default().targetedURL()!
        let items = FIFinderSyncController.default().selectedItemURLs() ?? []
        let command = ScriptContext(currentDirectory: target, items: items)
        
        let script = current!.fromTag(item.tag)!
        
        CommandRunner(command: command, script: script).runInParentApp()
    }
}

