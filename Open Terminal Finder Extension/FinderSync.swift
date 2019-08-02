//
//  FinderSync.swift
//  FinderExtension
//
//  Created by Quentin PÂRIS on 23/02/2016.
//  Copyright © 2018 Quentin PÂRIS. All rights reserved.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    var myFolderURL: URL = URL(fileURLWithPath: "/")
    
    override init() {
        super.init()
        
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath)
        
        // Set up the directory we are syncing.
        var directoryUrls = Set<URL>();
        directoryUrls.insert(self.myFolderURL);
        FIFinderSyncController.default().directoryURLs = directoryUrls;
    }
    
    lazy var scripts: [Script] = Script.fetch(url: scriptsURL)
    lazy var scriptsURL = try! FileManager.default.url(for: .applicationScriptsDirectory, in: .allDomainsMask, appropriateFor: nil, create: true)
    
    override func menu(for menu: FIMenuKind) -> NSMenu? {
        // Produce a menu for the extension.
        let menu = NSMenu(title: NSLocalizedString("Executor", comment:""))
        let item = menu.addItem(withTitle:  NSLocalizedString("Executor", comment:""), action: nil, keyEquivalent: "")
        item.submenu = NSMenu()
    
        scripts = Script.fetch(url: scriptsURL)
        for (i, script) in scripts.enumerated() {
            let sub = item.submenu!.addItem(withTitle: script.title, action: #selector(executeScript), keyEquivalent: "")
            sub.tag = i
        }
        
        item.submenu!.addItem(withTitle: "Scripts", action: #selector(openScriptsDirectory), keyEquivalent: "")
        
        return menu
    }
    
    @objc func openScriptsDirectory() {
        NSWorkspace.shared.open(scriptsURL)
    }
    
    @objc func executeScript(item: NSMenuItem) {
        let script = scripts[item.tag]
        let target = FIFinderSyncController.default().targetedURL()!
        script.execute(target: target)
    }
    
    
//    @IBAction func openTerminal(sender: AnyObject?) {
//        let target = FIFinderSyncController.default().targetedURL()
//
//        guard let targetPath = target?.path.replacingOccurrences(of: " ", with: "%20"), let url = URL(string:"terminal://"+targetPath) else {
//            return
//        }
//
//        NSWorkspace.shared.open(url)
//    }
    
}

