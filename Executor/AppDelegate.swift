//
//  AppDelegate.swift
//  Executor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(openURL),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        
        RunScriptCommand.runInTerminal()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        exit(0)
    }
    
    @objc func openURL(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        RunScriptCommand.runInTerminal()
    }
}

