//
//  AppDelegate.swift
//  Executor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa

struct CommandRunner {
    let command: RunScriptCommand
    
    func run() {
        let fm = FileManager.default
        let scriptURL = command.script.url
        
        if !fm.fileExists(atPath: scriptURL.path) {
            fatalError()
        }
        
        if !fm.isExecutableFile(atPath: scriptURL.path) {
            execute("/bin/chmod", ["+x", scriptURL.path])
        }
        
        let source = """
        tell application "Terminal"
        set shell to do script "cd '\(command.currentDirectory.path)'"
        do script "EXECUTOR='\(command.script.url.path)'" in shell
        do script "clear" in shell
        activate in shell
        do script "\\"$EXECUTOR\\"" in shell
        end tell
        """
        
        print(source)
        
        let script = NSAppleScript(source: source)
        
        var errorInfo: NSDictionary?
        script?.executeAndReturnError(&errorInfo)
        assert(errorInfo == nil, "\(errorInfo!)")
        
        exit(0)
    }
    
    static func testRun() {
        var scripts = ScriptInfo.load()
        
        if scripts.isEmpty {
            let url = scriptsURL.appendingPathComponent("hello_world.sh")
            try! "ls".write(to: url, atomically: true, encoding: .utf8)
            scripts = ScriptInfo.load()
        }
        
        let script = scripts.first(where: { $0.url.lastPathComponent == "hello_world.sh"})!
        let command = RunScriptCommand(currentDirectory: URL(fileURLWithPath: NSHomeDirectory()), script: script, items: nil)
        CommandRunner(command: command).run()
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


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        //https://github.com/qparis/FinderOpenTerminal
        
        let pluginsURL = Bundle.main.builtInPlugInsURL!
        let plugins = try! FileManager.default.contentsOfDirectory(at: pluginsURL, includingPropertiesForKeys: nil, options: [])
        execute("/usr/bin/pluginkit", ["-e", "use", "-a", plugins[0].path])
        
        //execute("/usr/bin/pluginkit", ["-e", "use", "-i", "szotp.Executor.FinderExecutor"])
        //execute("/usr/bin/killall", ["Finder"])
        
        CommandRunner.testRun()
        exit(0)
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        let url = urls[0]
        NSLog("\(url)")
        let decoded = RunScriptCommand.decode(url: url)
        
        CommandRunner(command: decoded).run()
    }
}
