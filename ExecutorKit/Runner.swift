//
//  CommandRunner.swift
//  ExecutorService
//
//  Created by pszot on 04/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Foundation
import Cocoa

extension URL {
    var shellPath: String {
        return path.replacingOccurrences(of: " ", with: "\\ ")
    }
}

public struct CommandRunner {
    let command: ScriptContext
    let script: ScriptInfo
    
    public init(command: ScriptContext, script: ScriptInfo) {
        self.command = command
        self.script = script
    }

    public func runInParentApp() {
        let url: URL
        let launcherName = script.launcher
        
        if launcherName != "none" {
            url = scriptsURL.appendingPathComponent(script.launcher)
        } else {
            url = script.url
        }
        
        let task = try! NSUserUnixTask(url: url)
        var arguments: [String] = []
        arguments.append(command.currentDirectory.path)
        arguments.append(script.url.path)
        
        for item in command.items {
            arguments.append(item.path)
        }
        
        dlog("NSUserUnixTask \(task.scriptURL.path) \(arguments)")
        
        
        task.execute(withArguments: arguments) { (error) in
            dlog(error)
        }
    }
    
    public static func openScriptsDirectory() {
        let url = scriptsURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        NSWorkspace.shared.open(url)
    }
}

public func execute(_ path: String?, _ arguments: [String]?, currentDirectoryURL: URL? = nil) {
    let task = Process()
    let pipe = Pipe()
    
    if let url = currentDirectoryURL {
        task.currentDirectoryURL = url
    }
    
    task.launchPath = path
    task.arguments = arguments
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    task.waitUntilExit()
    
    let handle = pipe.fileHandleForReading
    let data = handle.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)!
    print(output)
    
    assert(task.terminationStatus == 0)
}
