//
//  AppDelegate.swift
//  Executor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa

func copyScriptsIfNeeded() {
    let fromBundle = Bundle.main.url(forResource: "Scripts", withExtension: nil)!
    let contents = try! fm.contentsOfDirectory(at: fromBundle, includingPropertiesForKeys: nil, options: [])
    
    try? fm.createDirectory(at: scriptsURL, withIntermediateDirectories: true, attributes: nil)
    
    for file in contents {
        var destination = scriptsURL.appendingPathComponent(file.lastPathComponent)
        
        if file.lastPathComponent == "launcher" {
            destination = launcherURL
        }
        
        try? fm.removeItem(at: destination)
        //try! fm.createSymbolicLink(at: destination, withDestinationURL: file)
        try! fm.copyItem(at: file, to: destination)
    }
    
    assert(fm.fileExists(atPath: launcherURL.path))
}

func enableExtension() {
    dlog("enabling extension")
    
    
    let pluginsURL = Bundle.main.builtInPlugInsURL!
    let plugins = try! FileManager.default.contentsOfDirectory(at: pluginsURL, includingPropertiesForKeys: nil, options: [])
    execute("/usr/bin/pluginkit", ["-e", "use", "-a", plugins[0].path])
    
    //execute("/usr/bin/pluginkit", ["-e", "use", "-i", "szotp.Executor.FinderExecutor"])
}

copyScriptsIfNeeded()
enableExtension()
print(ScriptData.load().json)
