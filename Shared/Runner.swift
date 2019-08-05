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
    
//    func run() {
//        dlog("CommandRunner.run")
//        
//        let fm = FileManager.default
//        let scriptURL = command.script.url
//        
//        if !fm.fileExists(atPath: scriptURL.path) {
//            fatalError()
//        }
//        
//        if !fm.isExecutableFile(atPath: scriptURL.path) {
//            execute("/bin/chmod", ["+x", scriptURL.path])
//        }
//        
//        var shellSource: [String] = []
//        shellSource.append("cd " + command.currentDirectory.shellPath)
//        shellSource.append(command.script.url.shellPath)
//        
//        
//        let source = """
//        tell application "Terminal"
//            set shell to do script "cd '\(command.currentDirectory.path)'"
//            do script "EXECUTOR='\(command.script.url.path)'" in shell
//            do script "clear" in shell
//            activate in shell
//            do script "\\"$EXECUTOR\\"" in shell
//        end tell
//        """
//        
//        print(source)
//        
//        let script = NSAppleScript(source: source)
//        
//        var errorInfo: NSDictionary?
//        script?.executeAndReturnError(&errorInfo)
//        assert(errorInfo == nil, "\(errorInfo!)")
//        
//        exit(0)
//    }
    
    static func testRunner() -> CommandRunner {
        var scripts = ScriptData.load()
        
        if scripts.script.isEmpty {
            let url = scriptsURL.appendingPathComponent("hello_world.sh")
            try! "ls".write(to: url, atomically: true, encoding: .utf8)
            scripts = ScriptData.load()
        }
        
        let script = scripts.script.first(where: { $0.url.lastPathComponent == "hello_world.sh"})!
        let command = RunScriptCommand(currentDirectory: URL(fileURLWithPath: NSHomeDirectory()), script: script, items: nil)
        return CommandRunner(command: command)
    }
    
    func runInParentApp() {
        let task = try! NSUserUnixTask(url: launcherURL)
        
        var arguments: [String] = []
        arguments.append(command.currentDirectory.path)
        arguments.append(command.script.url.path)
        
        for item in command.items ?? [] {
            arguments.append(item.path)
        }
        
        dlog("NSUserUnixTask")
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
