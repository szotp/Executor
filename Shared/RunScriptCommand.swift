//
//  RunScriptCommand.swift
//  Executor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa

let fm = FileManager.default

func dlog(_ x: Any?) {
    if let x = x {
        NSLog("\(x)")
    }
}

public let scriptsURL: URL = {
    let fm = FileManager.default
    var result = try! fm.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    result.deleteLastPathComponent()
    result.appendPathComponent("szotp.Executor.FinderExecutor")
    return result
}()

public let launcherURL = scriptsURL.appendingPathComponent("launcher")


struct ScriptInfo: Codable {
    let url: URL
    let title: String
    
    static func fromURL(_ url: URL) -> ScriptInfo {
        return ScriptInfo(url: url, title: url.lastPathComponent)
    }
    
    static func isScript(url: URL) -> Bool {
        if url == launcherURL {
            return false
        }
        
        let name = url.lastPathComponent
        let ext = url.pathExtension
        
        if name.starts(with: ".") {
            return false
        }
        
        return fm.isExecutableFile(atPath: url.path) || ext == "sh" || ext == ""
    }
    
    static func load() -> [ScriptInfo] {
        let dir = scriptsURL

        if !fm.fileExists(atPath: dir.path) {
            try! fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let contents = try! fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isExecutableKey], options: [])
        return contents.filter(isScript).map(ScriptInfo.fromURL)
    }
}

struct RunScriptCommand: Codable {
    let currentDirectory: URL
    let script: ScriptInfo
    let items: [URL]?
    
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
}
