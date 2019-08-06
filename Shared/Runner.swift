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

struct CommandRunner {
    let command: RunScriptCommand

    func runInParentApp() {
        let url: URL
        let launcherName = command.script.launcher
        
        if launcherName != "none" {
            url = scriptsURL.appendingPathComponent(command.script.launcher)
        } else {
            url = command.script.url
        }
        
        let task = try! NSUserUnixTask(url: url)
        var arguments: [String] = []
        arguments.append(command.currentDirectory.path)
        arguments.append(command.script.url.path)
        
        for item in command.items {
            arguments.append(item.path)
        }
        
        dlog("NSUserUnixTask \(task.scriptURL.path) \(arguments)")
        
        
        task.execute(withArguments: arguments) { (error) in
            dlog(error)
        }
    }
    
    static func openScriptsDirectory() {
        let url = scriptsURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        NSWorkspace.shared.open(url)
    }
}

func execute(_ path: String?, _ arguments: [String]?, currentDirectoryURL: URL? = nil) {
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
