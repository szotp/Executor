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
    
    func enableExtension() {
        dlog("enabling extension")
        let pluginsURL = Bundle.main.builtInPlugInsURL!
        let plugins = try! FileManager.default.contentsOfDirectory(at: pluginsURL, includingPropertiesForKeys: nil, options: [])
        execute("/usr/bin/pluginkit", ["-e", "use", "-a", plugins[0].path])
        
        //execute("/usr/bin/pluginkit", ["-e", "use", "-i", "szotp.Executor.FinderExecutor"])
        //execute("/usr/bin/killall", ["Finder"])
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        //https://github.com/qparis/FinderOpenTerminal
        
        enableExtension()
        //CommandRunner.testRunner().runThroughService()
        
        
        //CommandRunner.testRunner().run()
        //Thread.sleep(forTimeInterval: 0.5)
        exit(0)
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        let url = urls[0]
        dlog("\(url)")
        let decoded = RunScriptCommand.decode(url: url)
        
        CommandRunner(command: decoded).run()
        //exit(0)
    }
}
