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
        
        if !fm.fileExists(atPath: dir.path) {
            try! fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let contents = try! fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])
        for file in contents {
            if fm.isExecutableFile(atPath: file.path) || file.pathExtension == "sh" || file.pathExtension == "" {
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
    
    static func decode(url: URL) -> RunScriptCommand {
        var string = url.absoluteString
        let range = string.range(of: "executor://")!
        string.replaceSubrange(range, with: "")
        

        let data = Data(base64Encoded: string)!
        let decoder = JSONDecoder()
        return try! decoder.decode(self, from: data)
    }
    
    func encode() -> URL {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        return URL(string: "executor://" + data.base64EncodedString())!
    }
    
    func sendToParent() {
        NSWorkspace.shared.open(encode())
    }
}
