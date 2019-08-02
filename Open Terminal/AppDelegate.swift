//
//  AppDelegate.swift
//  Open Terminal
//
//  Created by Quentin PÂRIS on 23/02/2016.
//  Copyright © 2018 Quentin PÂRIS. All rights reserved.
//

import Cocoa
import Darwin

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("Installing Finder extension")
        SwiftySystem.execute(path: "/usr/bin/pluginkit", arguments: ["-e", "use", "-i", "szotp.executor.extension"])
        SwiftySystem.execute(path: "/usr/bin/killall",arguments: ["Finder"])
        //helpMe()
        exit(0)
    }
    
    public func application(_ application: NSApplication, open urls: [URL]) {
//        if let unwrappedPath = urls.first?.absoluteURL.path {
//            if(FileManager.default.fileExists(atPath: unwrappedPath)) {
//                SwiftySystem.execute(path: "/usr/bin/open", arguments: ["-b", "com.apple.terminal", unwrappedPath])
//            } else {
//                helpMe(customMessage: "The specified directory does not exist")
//            }
//        }
        
        exit(0);
    }

    
    private func helpMe(customMessage: String) {
        let alert = NSAlert()
        alert.messageText = "Information"
        alert.informativeText = customMessage
        alert.runModal()
    }
    
    private func helpMe() {
        helpMe(customMessage: "This application adds a \"Open a terminal\" item in every Finder context menus.\n\n(c) Quentin PÂRIS 2018 - http://quentin.paris")
    }
}

