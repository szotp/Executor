//
//  RunScriptCommand.swift
//  Executor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa

private let groupName = "RsrSJD54Rq6XkDxvB6XjIMsf.Executor"
public let groupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)!
public let scriptsURL = groupContainerURL.appendingPathComponent("Scripts")

func dlog(_ x: Any) {
    NSLog("\(x)")
}

struct ScriptInfo: Codable {
    let url: URL
    let title: String
    
    static func load() -> [ScriptInfo] {
        var result: [ScriptInfo] = []
        let dir = scriptsURL
        let fm = FileManager.default
        
        let contents = try! fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])
        for file in contents {
            if fm.isExecutableFile(atPath: file.path) || file.pathExtension == "sh" {
                result.append(ScriptInfo(url: file, title: file.lastPathComponent))
            }
        }
        
        return result
    }
}

struct RunScriptCommand: Codable {
    let currentDirectory: URL
    let script: ScriptInfo
    let items: [URL]?
    
    static func openScriptsDirectory() {
        let url = scriptsURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        NSWorkspace.shared.open(url)
    }
    
    static func runInTerminal() {
        let url = groupContainerURL.appendingPathComponent("script.sh")
        print(url.path)
        
        let appURL = URL(fileURLWithPath: "/Applications/Utilities/Terminal.app")
        
        let copyToURL = URL(fileURLWithPath: NSHomeDirectory() + "/Desktop/script.sh")
        try? FileManager.default.copyItem(at: url, to: copyToURL)
        
        let configuration = [NSWorkspace.LaunchConfigurationKey.arguments: [copyToURL]]
        try! NSWorkspace.shared.launchApplication(at: appURL, options: [], configuration:configuration)
    }
    
    func sendToParent() {
        var content: [String] = []
        content.append("cd \(currentDirectory.path)")
        content.append("chmod +x \(script.url.path)")
        content.append("\(script.url.path)")
        
        let url = groupContainerURL.appendingPathComponent("script.sh")
        try? FileManager.default.removeItem(at: url)
        try! content.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        
        NSWorkspace.shared.open(URL(string: "executor://runInTerminal")!)
    }
}
