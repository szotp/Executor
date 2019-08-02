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
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        exit(0)
    }
    
    @objc func openURL(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        dlog("event")
        let urlString = event.paramDescriptor(forKeyword: keyDirectObject)!.stringValue!
        let url = URL(string: urlString)!
        let parsed = RunScriptCommand.decode(url: url)
        
        dlog(url)
        dlog("\(parsed)")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

